# CV32E40P SoC Firmware

TEKNOFEST 2026 Çip Tasarım Yarışması — Mikrodenetleyici Kategorisi

## Dizin Yapısı

```
firmware/
├── linker.ld           ← Memory map ve section yerleşimi
├── boot.S              ← RISC-V startup kodu (stack, bss, data init)
├── Makefile            ← Build sistemi
├── include/            ← Header dosyaları (register map'ler + API)
│   ├── soc.h           ← Base adresler, ortak makrolar
│   ├── uart.h
│   ├── gpio.h
│   ├── timer.h
│   ├── i2c.h
│   └── qspi.h
└── src/                ← C driver implementasyonları + main
    ├── uart.c
    ├── gpio.c
    ├── timer.c
    ├── i2c.c
    ├── qspi.c
    └── main.c
```

## Build

```bash
# Önkoşul: riscv32-unknown-elf-gcc toolchain
#   Ubuntu: sudo apt install gcc-riscv64-unknown-elf
#           (cross-toolchain hem rv32 hem rv64 destekler)

make
```

Çıktılar `build/` altına gelir:
- `firmware.elf` — symbol'lu, GDB debug için
- `firmware.bin` — ham binary
- `firmware.hex` — Verilog `$readmemh` formatı, Vivado BRAM init için
- `firmware.dis` — disassembly
- `firmware.map` — linker memory map

```bash
make clean   # build temizle
make size    # firmware boyutunu göster
```

## Vivado'ya Entegrasyon

Boot ROM BRAM'ini `firmware.hex` ile init etmek için:

**Yöntem 1 — IP Catalog'dan Block Memory Generator:**
- Coe dosyası gerekiyorsa: hex → coe dönüşümü yapın
- Veya doğrudan `firmware.bin`'i sentez sırasında BRAM init için kullanın

**Yöntem 2 — Doğrudan RTL'den $readmemh:**

```systemverilog
// boot_bram içinde:
initial begin
    $readmemh("firmware.hex", mem);
end
```

CV32E40P reset adresi 0x0000_0000 olmalı (top_module'de `boot_addr_i` parametresi). Bu zaten linker'daki IMEM ORIGIN ile örtüşüyor.

## Bellek Haritası

| Bölge        | Base         | Boyut | İçerik              |
|--------------|--------------|-------|---------------------|
| Boot ROM     | 0x0000_0000  | 4KB   | Kod + .data init    |
| Instr RAM    | 0x1000_0000  | 4KB   | (şimdilik kullanılmıyor) |
| Data RAM     | 0x2000_0000  | 4KB   | .data + .bss + stack |
| Timer        | 0x4000_0000  | —     | AXI4-Lite slave     |
| GPIO         | 0x4001_0000  | —     | AXI4-Lite slave     |
| I2C Master   | 0x4002_0000  | —     | AXI4-Lite slave     |
| QSPI Master  | 0x4003_0000  | —     | AXI4-Lite slave     |
| UART         | 0x4004_0000  | —     | AXI4-Lite slave     |

## main.c Akışı

1. UART init (115200 baud, sabit)
2. Boot mesajı yaz
3. GPIO test (4 pattern, IDR oku)
4. Timer test (1 saniye gecikme, event count doğrulama)
5. QSPI test (JEDEC ID + status oku)
6. I2C test (opsiyonel, slave varsa)
7. Heartbeat loop (her saniye UART mesaj + GPIO LED toggle)

## Şartname Uyumluluğu Notları

Mevcut RTL ile TEKNOFEST 2026 v1.3 şartnamesi arasında bazı farklar var. Bunlar driver'ların `.h` dosyalarındaki yorumlarda detaylıca belirtildi. RTL güncellendiğinde driver'lar da güncellenmelidir.

Özet farklar:
- **UART**: Şartname UART_CPB ile baud rate ayarlanır, UART_STP register'ı stop bit için var. Mevcut RTL sabit baud rate kullanıyor.
- **UART CFG flags**: Şartname CFG[1] ve CFG[2]'nin SW tarafından `0`'a çekilmesini istiyor. RTL şu an HW set sonrası yeni CFG yazımıyla üzerine yazma şeklinde çalışıyor.
- **I2C**: Şartnamede `I2C_CFG_CLR` register'ı yok, CFG bit'leri doğrudan SW yazımıyla temizleniyor. RTL'de ayrı bir CLR register var (0x14).
- **QSPI**: RTL'de 0x14'te `address` flag var, şartnamede yok. Şartnamede prescaler `(N+1)` bölücü, RTL'de `2N` bölücü.
- **BRAM**: Şartname 8KB istiyor, RTL şu an 4KB (ADDR_WIDTH=10). Linker güncellenmesi gerekecek.
