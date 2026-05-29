# =====================================================================
#  Makefile — CV32E40P SoC Firmware
#  --------------------------------------------------
#  Hedefler:
#    make        → donanım build'i (gerçek gecikmeler)
#    make sim    → simülasyon build'i (-DSIMULATION, gecikmeler 1000x kısa)
#    make clean  → build/ dizinini sil
#    make size   → firmware boyut raporu
#
#  Çıktılar (build/ altında):
#    firmware.elf  → debug için (symbol'lu)
#    firmware.bin  → ham binary
#    firmware.hex  → Verilog $readmemh formatı (Vivado BRAM init / simülasyon)
#    firmware.dis  → disassembly
#    firmware.map  → linker memory haritası
# =====================================================================

# --- Toolchain ön eki ---
#  Toolchain'in riscv64-unknown-elf- ise: make CROSS=riscv64-unknown-elf-
CROSS   ?= riscv32-unknown-elf-
CC       = $(CROSS)gcc
OBJCOPY  = $(CROSS)objcopy
OBJDUMP  = $(CROSS)objdump
SIZE     = $(CROSS)size

# --- Hedef mimari ---
#  zicsr   : CSR buyrukları (csrr/csrw — trap/interrupt için şart)
#  zifencei: fence.i buyruğu (instruction-fetch fence)
#  GCC 12+ bunları base ISA'dan ayırdı, explicit belirtmek gerekiyor.
ARCH     = rv32imc_zicsr_zifencei
ABI      = ilp32            # 32-bit int/long/pointer, soft-float

# --- Dizinler ---
SRC_DIR  = src
INC_DIR  = include
BUILD    = build

# --- Kaynak dosyalar ---
ASM_SRCS = boot.S
C_SRCS   = $(wildcard $(SRC_DIR)/*.c)   # src/ icindeki tum .c dosyalari
LINKER   = linker.ld

# --- Object dosyaları (kaynak → build/*.o eşlemesi) ---
ASM_OBJS = $(ASM_SRCS:%.S=$(BUILD)/%.o)
C_OBJS   = $(C_SRCS:$(SRC_DIR)/%.c=$(BUILD)/%.o)
OBJS     = $(ASM_OBJS) $(C_OBJS)

# --- Ortak derleme flag'leri ---
#  EXTRA_FLAGS: 'make sim' bunu -DSIMULATION ile doldurur
COMMON_FLAGS = -march=$(ARCH) -mabi=$(ABI) \
               -I$(INC_DIR) \
               -Os -g \
               -ffunction-sections -fdata-sections \
               -Wall -Wextra \
               $(EXTRA_FLAGS)

CFLAGS   = $(COMMON_FLAGS) -std=c11
ASFLAGS  = $(COMMON_FLAGS)

# --- Link flag'leri ---
LDFLAGS  = -march=$(ARCH) -mabi=$(ABI) \
           -T $(LINKER) \
           -nostdlib -nostartfiles \
           -Wl,--gc-sections \
           -Wl,-Map=$(BUILD)/firmware.map

TARGET   = $(BUILD)/firmware

.PHONY: all sim clean size

# =====================================================================
#  Donanım build'i — gerçek gecikmeler
# =====================================================================
all: $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dis size

# =====================================================================
#  Simülasyon build'i — gecikmeler 1000x kısa (-DSIMULATION)
#  Önce clean yapar (eski .o'lar SIMULATION'sız derlenmiş olabilir),
#  sonra EXTRA_FLAGS ile yeniden derler.
# =====================================================================
sim:
	$(MAKE) clean
	$(MAKE) all EXTRA_FLAGS=-DSIMULATION
	@echo ""
	@echo ">>> SIMULATION build hazir — gecikmeler 1000x kisaltildi."
	@echo ">>> build/firmware.hex dosyasini simulasyonda kullan."

# --- build/ dizinini oluştur ---
$(BUILD):
	mkdir -p $(BUILD)

# --- Assembly derleme: boot.S → build/boot.o ---
$(BUILD)/%.o: %.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

# --- C derleme: src/xxx.c → build/xxx.o ---
$(BUILD)/%.o: $(SRC_DIR)/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

# --- Link: tüm .o'lar → firmware.elf ---
$(TARGET).elf: $(OBJS) $(LINKER) | $(BUILD)
	$(CC) $(LDFLAGS) $(OBJS) -o $@

# --- ELF → ham binary ---
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# --- ELF → Verilog hex ($readmemh formatı) ---
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O verilog $< $@

# --- ELF → disassembly ---
$(TARGET).dis: $(TARGET).elf
	$(OBJDUMP) -d -S $< > $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# --- Boyut raporu ---
size: $(TARGET).elf
	@echo ""
	@echo "=== Firmware Size ==="
	@$(SIZE) $(TARGET).elf
	@echo ""

# --- Temizlik ---
clean:
	rm -rf $(BUILD)
