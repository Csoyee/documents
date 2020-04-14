#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>

#include <linux/fs.h>
#include <sys/ioctl.h>
#define BLOCKSIZE 4*1024*1024

#define FILESIZE 1024*1024*1024


int main (int argc, char * argv[]) {

	int fd;
	int ret; 
	struct fstrim_range fsr;

	fd = open("/home/csoyee/ssd/testfile.0.0", O_RDWR, 0777);
	if(fd < 0) {
		perror("OPEN");
		return -1 ;
	}

	// trim
	fsr.start = 0;
	fsr.len = atoi(argv[1]);
	fsr.minlen = atoi(argv[1]);

	printf("length:: %lld\n", fsr.len);

	for(int i=0 ; i<16384; i++) {
		ret = fallocate(fd, (FALLOC_FL_KEEP_SIZE | FALLOC_FL_PUNCH_HOLE), 
						fsr.start, fsr.len);
		if(ret != 0) {
			perror("PUCHHOLE");
		}
		fsr.start += 2*fsr.len;
		//fsr.start += FILESIZE/1024;
	}

	fsync(fd);



	close(fd);

	return 0;
}
