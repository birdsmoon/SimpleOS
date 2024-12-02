BUILD:=../build
SRC:=.

ENTRYPOINT:=0x10000 # 变量定义

CFLAGS:= -m32
CFLAGS+= -fno-builtin # 不需要gcc内置函数
CFLAGS+= -nostdinc # 不需要标准头文件
CFLAGS+= -fno-pic  # 不需要位置无关的代码
CFLAGS+= -fno-pie  # 不需要位置无关的可执行程序
CFLAGS+= -nostdlib #不需要标准库
CFLAGS+= -fno-stack-protector #不需要栈保护
CFLAGS:=$(strip $(CFLAGS))
DEBUG:= -g

INCLUDE:=-I$(SRC)/include
# 编译引导程序
$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@
# 编译内核
$(BUILD)/kernel/%.o: $(SRC)/kernel/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f elf32 $(DEBUG) $< -o $@
$(BUILD)/kernel/%.o: $(SRC)/kernel/%.c
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG) $(INCLUDE) -c $< -o $@
$(BUILD)/lib/%.o: $(SRC)/lib/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f elf32 $(DEBUG) $< -o $@
$(BUILD)/lib/%.o: $(SRC)/lib/%.c
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG) $(INCLUDE) -c $< -o $@
# 内核连接
$(BUILD)/kernel.bin: \
	$(BUILD)/kernel/start.o \
	$(BUILD)/kernel/main.o \
	$(BUILD)/kernel/io.o \
	$(BUILD)/kernel/console.o \
	$(BUILD)/kernel/printk.o \
	$(BUILD)/kernel/assert.o \
	$(BUILD)/kernel/debug.o \
	$(BUILD)/lib/string.o \
	$(BUILD)/lib/vsprintf.o \
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -static $^ -o $@ -Ttext $(ENTRYPOINT)
# 转换内核为裸机格式
$(BUILD)/system.bin: $(BUILD)/kernel.bin
	objcopy -O binary $< $@
# 生成符号位
$(BUILD)/system.map: $(BUILD)/kernel.bin
	nm $< | sort > $@
# 生成硬盘镜像文件
$(BUILD)/master.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin \
	$(BUILD)/system.bin \
	$(BUILD)/system.map 
	yes | bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@
	dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc
	dd if=$(BUILD)/system.bin of=$@ bs=512 count=200 seek=10 conv=notrunc
# 写入引导扇区到USB设备
# .PHONY: usb
# usb:$(BUILD)/boot/boot.bin /dev/sdb
# 	sudo dd if=/dev/sdb of=tmp.bin bs=512 count=1 conv=notrunc
# 	cp tmp.bin sub.bin
# 	sudo rm tmp.bin
# 	dd if=$(BUILD)/boot/boot.bin of=usb.bin bs=446 count=1 conv=notrunc
# 	sudo dd if=usb.bin of=tmp.bin bs=512 count=1 conv=notrunc
# 	rm sub.bin
# 测试
test: $(BUILD)/master.img
# 清理
.PHONY: clean
clean:
	rm -rf $(BUILD).bin
	rm -rf $(BUILD).img.lock
# 使用Bochs模拟器运行
.PHONY: bochs
bochs:$(BUILD)/master.img
	bochs -q -f ../bochs/bochsrc
.PHONY: qemu
qemu:$(BUILD)/master.img
	qemu-system-i386 \
	-m 32M \
	-boot c \
	-hda $<
.PHONY: qemug
qemu:$(BUILD)/master.img
	qemu-system-i386 \
	-s -S \
	-m 32M \
	-boot c \
	-hda $<
.PHONY: bochsg
bochsg:$(BUILD)/master.img
	bochs-gdb -q -f ../bochs/bochsrc.gdb
$(BUILD)/master.vmdk: $(BUILD)/master.img
	qemu-img convert -O vmdk $< $@

.PHONY:vmdk
vmdk: $(BUILD)/master.vmdk