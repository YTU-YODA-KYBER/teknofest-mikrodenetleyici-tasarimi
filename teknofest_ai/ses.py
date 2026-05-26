import tensorflow as tf
import numpy as np
import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# ============================================================
# SES ÖN İŞLEME SCRİPTİ
# TF C++ AudioSpectrogram int16 değerleri direkt kullanıyor.
# ============================================================

file_name  = "yes22.wav"           # ses dosyan
model_path = "micro_speech.tflite"
output_hex = "input_data.hex"

try:
    print(f"1. '{file_name}' okunuyor (normalizasyon YOK)...")
    if not os.path.exists(file_name):
        raise FileNotFoundError(f"'{file_name}' bulunamadi!")

    audio_binary = tf.io.read_file(file_name)
    audio, _ = tf.audio.decode_wav(
        audio_binary, desired_channels=1, desired_samples=16000
    )
    audio = tf.squeeze(audio, axis=-1)

    print("2. Log-Mel Spektrogram (TF C++ ile birebir)...")
    spectrogram = tf.raw_ops.AudioSpectrogram(
        input=tf.expand_dims(audio, -1),
        window_size=480,
        stride=320,
        magnitude_squared=True
    )
    mel_w = tf.signal.linear_to_mel_weight_matrix(
        num_mel_bins=40,
        num_spectrogram_bins=spectrogram.shape[-1],
        sample_rate=16000,
        lower_edge_hertz=20.0,
        upper_edge_hertz=4000.0
    )
    log_mel = tf.math.log(tf.matmul(spectrogram, mel_w) + 1e-6)
    features = log_mel.numpy()[0][:49, :40]

    print(f"   Log-mel aralik: {features.min():.2f} ile {features.max():.2f}")
    if features.max() < 0:
        print("   UYARI: Tüm log-mel değerleri negatif — ses çok sessiz veya normalizasyon var!")

    print("3. TFLite Quantization parametreleri alınıyor...")
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    inp_det = interpreter.get_input_details()[0]
    out_det  = interpreter.get_output_details()[0]

    input_scale      = inp_det['quantization_parameters']['scales'][0]
    input_zero_point = int(inp_det['quantization_parameters']['zero_points'][0])
    print(f"   scale={input_scale:.8f}, zero_point={input_zero_point}")

    int8_features = np.clip(
        np.round(features / input_scale + input_zero_point),
        -128, 127
    ).astype(np.int8)

    print(f"   int8 aralik: {int8_features.min()} ile {int8_features.max()}")
    print(f"   -128 olan: {np.sum(int8_features==-128)} ({100*np.mean(int8_features==-128):.1f}%)")

    if int8_features.max() < 0:
        print("   HATA: Tüm değerler negatif, ses normalizasyonunu kaldır!")

    print("4. TFLite ile doğrulama...")
    interpreter.set_tensor(inp_det['index'], int8_features.reshape(inp_det['shape']))
    interpreter.invoke()
    out = interpreter.get_tensor(out_det['index'])[0]

    labels = ["Sessizlik", "Bilinmeyen", "Evet", "Hayir"]
    print("\n   === TFLite REFERANS SONUCU ===")
    for i, (s, l) in enumerate(zip(out, labels)):
        print(f"   [{i}] {l:12s}: {int(s):5d}")
    winner = int(np.argmax(out))
    print(f"   Kazanan: [{winner}] {labels[winner]}")

    if winner == 2:
        print("\n   ✓ EVET diyor! Vivado'da da Evet çıkacak.")
    else:
        print(f"\n   ✗ {labels[winner]} diyor.")
        print("   Ses dosyasını kontrol et veya resmi yes_1000ms.wav kullan.")

    with open(output_hex, "w") as f:
        for val in int8_features.flatten():
            f.write(f"{(int(val) & 0xFF):02X}\n")

    print(f"\n5. '{output_hex}' yazıldı — Vivado'ya kopyalayabilirsin.")

except Exception as e:
    import traceback; traceback.print_exc()
