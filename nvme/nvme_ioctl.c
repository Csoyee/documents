#include <inttypes.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/ioctl.h>

#include <linux/types.h>
#include <sys/ioctl.h>


#define NVME_IOCTL_IO_CMD	_IOWR('N', 0x43, struct nvme_passthru_cmd)

struct nvme_passthru_cmd {
	__u8	opcode;
	__u8	flags;
	__u16	rsvd1;
	__u32	nsid;
	__u32	cdw2;
	__u32	cdw3;
	__u64	metadata;
	__u64	addr;
	__u32	metadata_len;
	__u32	data_len;
	__u32	cdw10;
	__u32	cdw11;
	__u32	cdw12;
	__u32	cdw13;
	__u32	cdw14;
	__u32	cdw15;
	__u32	timeout_ms;
	__u32	result;
};



int submit_ioctl (int fd) {
	void* buf;


	if(posix_memalign(&buf, getpagesize(), 512)) {
		fprintf(stderr, "can not allocate payload\n");
		return 0;
	}

	memset (buf, 0, 512);

	strcpy ((char*)buf, "change!\n");

	struct nvme_passthru_cmd cmd = {
		.opcode		= 1,
		.flags		= 0,
		.rsvd1		= 0,
		.nsid		= 0,
		.cdw2		= 0,
		.cdw3		= 0,
		.metadata	= 0,
		.addr		= (__u64)(uintptr_t) buf,
		.metadata_len	= 0,
		.data_len	= 512,
		.cdw10		= 20,
		.cdw11		= 0,
		.cdw12		= 0,
		.cdw13		= 0,
		.cdw14		= 0,
		.cdw15		= 0,
		.timeout_ms	= 0,
		.result		= 0,
	};

	int err = ioctl(fd, NVME_IOCTL_IO_CMD, &cmd);

	printf("%d\n",err);
	return err;
}
