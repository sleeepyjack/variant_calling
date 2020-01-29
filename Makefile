all: environment.cpu.sif environment.gpu.sif

environment.cpu.sif: Singularity.cpu
	singularity build --fakeroot environment.cpu.sif Singularity.cpu

environment.gpu.sif: Singularity.gpu
	singularity build --fakeroot environment.gpu.sif Singularity.gpu

.PHONY: clean

clean:
	rm -rf environment.cpu.sif environment.gpu.sif