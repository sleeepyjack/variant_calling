all: environment.cpu.sif environment.gpu.sif

environment.cpu.sif: Singularity.cpu bootstrap_image.sh
	singularity build --fakeroot environment.cpu.sif Singularity.cpu

environment.gpu.sif: Singularity.gpu bootstrap_image.sh
	singularity build --fakeroot environment.gpu.sif Singularity.gpu

.PHONY: clean

clean:
	rm -rf *.sif
