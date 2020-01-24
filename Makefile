all: cpu.sif gpu.sif

cpu.sif: Singularity.cpu
	singularity build --fakeroot cpu.sif Singularity.cpu

gpu.sif: Singularity.gpu
	singularity build --fakeroot gpu.sif Singularity.gpu

.PHONY: clean

clean:
	rm -rf *.sif