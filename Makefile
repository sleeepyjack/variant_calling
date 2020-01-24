all: cpu.sif gpu.sif

cpu.sif: Singularity.cpu
	singularity build --fakeroot environment.cpu.sif Singularity.cpu

gpu.sif: Singularity.gpu
	singularity build --fakeroot environment.gpu.sif Singularity.gpu

.PHONY: clean

clean:
	rm -rf *.sif