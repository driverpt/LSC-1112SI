/*
 * The minix filesystem constants/structures
 */

/*
 * Thanks to Kees J Bot for sending me the definitions of the new
 * minix filesystem (aka V2) with bigger inodes and 32-bit block
 * pointers.
 */

#define MINIX_ROOT_INO 1

/* Not the same as the bogus LINK_MAX in <linux/limits.h>. Oh well. */
#define MINIX_LINK_MAX	250
#define MINIX2_LINK_MAX	65530

#define MINIX_I_MAP_SLOTS	8
#define MINIX_Z_MAP_SLOTS	64
#define MINIX_VALID_FS		0x0001		/* Clean fs. */
#define MINIX_ERROR_FS		0x0002		/* fs has errors. */

#define MINIX_INODES_PER_BLOCK (BLOCK_SIZE/INODE_SIZE)

/*
 * This is the original minix inode layout on disk.
 * Note the 8-bit gid and atime and ctime.
 */
typedef struct minix_inode {
	u16 i_mode;
	u16 i_uid;
	u32 i_size;
	u32 i_time;
	u8  i_gid;
	u8  i_nlinks;
	u16 i_zone[9];
} __attribute__((packed)) minix_inode;

/*
 * The new minix inode has all the time entries, as well as
 * long block numbers and a third indirect block (7+1+1+1
 * instead of 7+1+1). Also, some previously 8-bit values are
 * now 16-bit. The inode is now 64 bytes instead of 32.
 */
typedef struct minix2_inode {
	u16 i_mode;
	u16 i_nlinks;
	u16 i_uid;
	u16 i_gid;
	u32 i_size;
	u32 i_atime;
	u32 i_mtime;
	u32 i_ctime;
	u32 i_zone[10];
} __attribute__((packed)) minix2_inode;

/*
 * minix super-block data on disk
 */
typedef struct minix_super_block {
	u16 s_ninodes;
	u16 s_nzones;
	u16 s_imap_blocks;
	u16 s_zmap_blocks;
	u16 s_firstdatazone;
	u16 s_log_zone_size;
	u32 s_max_size;
	u16 s_magic;
	u16 s_state;
	u32 s_zones;
} __attribute__((packed)) minix_super_block;

/*
 * V3 minix super-block data on disk
 */
struct minix3_super_block {
	u32 s_ninodes;
	u16 s_pad0;
	u16 s_imap_blocks;
	u16 s_zmap_blocks;
	u16 s_firstdatazone;
	u16 s_log_zone_size;
	u16 s_pad1;
	u32 s_max_size;
	u32 s_zones;
	u16 s_magic;
	u16 s_pad2;
	u16 s_blocksize;
	u8  s_disk_version;
} __attribute__((packed)) minix3_super_block;

typedef struct minix_dir_entry {
	u16 inode;
	char name[0];
} __attribute__((packed)) minix_dir_entry;

typedef struct minix3_dir_entry {
	u32 inode;
	char name[0];
} __attribute__((packed)) minix3_dir_entry;
