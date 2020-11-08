#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>

#define RWH_WRITE_LIFE_NONE	0
#define RWH_WRITE_LIFE_NOT_SET	1
#define RWH_WRITE_LIFE_SHORT	2
#define RWH_WRITE_LIFE_MEDIUM	3
#define RWH_WRITE_LIFE_LONG	4
#define RWH_WRITE_LIFE_EXTREME 	5

int main () {

	int fd ;
	uint64_t hint = 6;

	if ((fd = open("/dev/nvme0n1", O_RDWR) )<0){
		perror("open");
		return 0;
	}


	if(fcntl(fd , 1036, &hint) < 0){
		perror("fcntl");
		return 0;
	}

	close (fd);

}
