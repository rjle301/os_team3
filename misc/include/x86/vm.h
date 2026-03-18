/**
** @file	vm.h
**
** @brief	Virtual memory-related declarations.
*/

#ifndef X86_VM_H_
#define X86_VM_H_

#include <defs.h>
#include <types.h>

/*
** General (C and/or assembly) definitions
*/

// number of entries in a page directory or page table
#define N_PDE          1024
#define N_PTE          1024

// index field shift counts and masks
#define PDIX_SHIFT     22
#define PTIX_SHIFT     12
#define PIX2I_MASK     0x3ff

// page-size address rounding macros
#define SZ_PG_M1       MOD4K_BITS
#define SZ_PG_MASK     MOD4K_MASK
#define PGUP(a)        (((a)+SZ_PG_M1) & SZ_PG_MASK)
#define PGDOWN(a)      ((a) & SZ_PG_MASK)

// page directory entry bit fields
#define PDE_P          0x00000001	// 1 = present
#define PDE_RW         0x00000002	// 1 = writable
#define PDE_US         0x00000004	// 1 = user and system usable
#define PDE_PWT        0x00000008	// cache: 1 = write-through
#define PDE_PCD        0x00000010	// cache: 1 = disabled
#define PDE_A          0x00000020	// accessed
#define PDE_AVL1       0x00000040	// ignored (4KB pages)
#define PDE_PS         0x00000080	// 1 = 4MB page size
#define PDE_G          0x00000100	// global
#define PDE_PAT        0x00000800	// (4KB pages) use page attribute table
#define PDE_AVL2       0x00000e00	// ignored
#define PDE_FA         0xfffff000	// frame address field (4KB pages)

// variations, 4MB page directory entries
#define PDE_4M_D       0x00000040	// dirty bit
#define PDE_4M_FA      0xffc1e000	// frame address field (4MB pages)
#define PDE_4M_FA_3122 0xffc00000   // frame address, bits 31:22
#define PDE_4M_FA_3932 0x00o1e000   // frame address, bits 39:32
#define PDE_4M_PAT     0x00001000   // (4MB) use page attribute table

// page table entry bit fields
#define PTE_P          0x00000001	// present
#define PTE_RW         0x00000002	// 1 = writable
#define PTE_US         0x00000004	// 1 = user and system usable
#define PTE_PWT        0x00000008	// cache: 1 = write-through
#define PTE_PCD        0x00000010	// cache: 1 = disabled
#define PTE_A          0x00000020	// accessed
#define PTE_D          0x00000040	// dirty
#define PTE_PAT        0x00000080	// use page attribute table
#define PTE_G          0x00000100	// global
#define PTE_AVL2       0x00000e00	// ignored
#define PTE_FA         0xfffff000	// frame address field

// error code bit assignments for page faults
#define PFLT_P         0x00000001
#define PFLT_W         0x00000002
#define PFLT_US        0x00000004
#define PFLT_RSVD      0x00000008
#define PFLT_ID        0x00000010
#define PFLT_PK        0x00000020
#define PFLT_SS        0x00000040
#define PFLT_HLAT      0x00000080
#define PFLT_SGX       0x00008000
#define PFLT_UNUSED    0xffff7f00

#ifndef ASM_SRC

/*
** Start of C-only definitions
*/

// convert a value into a frame number in the proper bit positions
#define	TO_FRAME(v)	((uint32_t) v) & 0xfffff000)

// create a pde/pte from an integer frame number and permission bits
#define MKPDE(f,p)  ((pde_t)( TO_FRAME((f)) | (p) ))
#define MKPTE(f,p)  ((pte_t)( TO_FRAME((f)) | (p) ))

// is a PDE/PTE present?
// (P bit is in the same place in both)
#define IS_PRESENT(entry)  (((entry) & PDE_P) != 0 )

// is a PDE a 4MB page entry?
#define IS_LARGE(pde)      (((pde) & PDE_PS) != 0 )

// is this entry "system only" or "system and user"?
#define IS_SYSTEM(entry)   (((entry) & PDE_US) == 0 )
#define IS_USER(entry)     (((entry) & PDE_US) != 0 )

// low-order nine bits of PDEs and PTEs hold "permission" flag bits
#define PERMS_MASK          MOD4K_BITS

// 4KB frame numbers are 20 bits wide
#define	FRAME_4K_SHIFT     12
#define FRAME2I_4K_MASK    0x000fffff
#define TO_4KFRAME(n)      (((n)&FRAME2I_4K_MASK) << FRAME_4K_SHIFT)
#define GET_4KFRAME(n)     (((n) >> FRAME_4K_SHIFT)&FRAME2I_4K_MASK)
#define PDE_4K_ADDR(n)     ((n) & MOD4K_MASK)
#define PTE_4K_ADDR(n)     ((n) & MOD4K_MASK)

// 4MB frame numbers are 10 bits wide
#define	FRAME_4M_SHIFT_L   22
#define FRAME_4M_SHIFT_U   12
#define FRAME2I_4M_MASK_L  0x000003ff
#define FRAME2I_4M_MASK_U  0x0000000f
#define TO_4MFRAME(u,l)    ( (((l)&FRAME2I_4M_MASK_U) << FRAME_4M_SHIFT_U) | \
	                         (((u)&FRAME2I_4M_MASK_U) << FRAME_4M_SHIFT_L) )
#define GET_4MFRAME_L(n)   (((n) >> FRAME_4M_SHIFT_L)&FRAME2I_4M_MASK_L)
#define GET_4MFRAME_U(n)   (((n) >> FRAME_4M_SHIFT_U)&FRAME2I_4M_MASK_U)
#define PDE_4M_ADDR(n)     ((n) & MOD4M_MASK)
#define PTE_4M_ADDR(n)     ((n) & MOD4M_MASK)

// extract the PMT address or frame address from a table entry
// PDEs could point to 4MB pages, or 4KB PMTs
#define PDE_ADDR(p) (IS_LARGE(p)?(((uint32_t)p)&PDE_FA):(((uint32_t)p)&PDE_PTA))
// PTEs always point to 4KB pages
#define PTE_ADDR(p) (((uint32_t)(p))&PTE_FA)
// everything has nine bits of permission flags
#define PERMS(p)    (((uint32_t)(p))&PERMS_MASK)

// extract the table indices from a 32-bit VA
#define PDIX(v)     ((((uint32_t)(v)) >> PDIX_SHIFT) & PIX2I_MASK)
#define PTIX(v)     ((((uint32_t)(v)) >> PTIX_SHIFT) & PIX2I_MASK)

// extract the byte offset from a 32-bit VA
#define OFFSET_4K(v)       (((uint32_t)(v)) & MOD4K_BITS)
#define OFFSET_4M(v)       (((uint32_t)(v)) & MOD4M_BITS)

/*
** Types
*/

// page directory entries

// as a 32-bit word, in types.h
// typedef uint32_t pde_t;

// PDE for 4KB pages
typedef struct pdek_s {
	uint_t p    :1;   // 0:  present
	uint_t rw   :1;   // 1:  writable
	uint_t us   :1;   // 2:  user/supervisor
	uint_t pwt  :1;   // 3:  cache write-through
	uint_t pcd  :1;   // 4:  cache disable
	uint_t a    :1;   // 5:  accessed
	uint_t avl1 :1;   // 6:  ignored (available)
	uint_t ps   :1;   // 7:  page size (must be 0)
	uint_t avl2 :4;   // 11-8:  ignored (available)
	uint_t fa   :20;  // 31-12:  frame address
} pdek_f_t;

// union to allow easy switching back and forth
typedef union pde4k_u {
	pde_t    a;
	pdek_f_t f;
} pde4k_t;

// PDE for 4MB pages
typedef struct pdem_s {
	uint_t p    :1;   // 0:  present
	uint_t rw   :1;   // 1:  writable
	uint_t us   :1;   // 2:  user/supervisor
	uint_t pwt  :1;   // 3:  cache write-through
	uint_t pcd  :1;   // 4:  cache disable
	uint_t a    :1;   // 5:  accessed
	uint_t d    :1;   // 6:  dirty
	uint_t ps   :1;   // 7:  page size (must be 1)
	uint_t g    :1;   // 8:  global
	uint_t avl  :3;   // 11-9:  ignored (available)
	uint_t pat  :1;   // 12:  page attribute table in use
	uint_t fa2  :4;   // 16-13:  bits 35-32 of frame address (36-bit addrs)
	uint_t rsv  :5;   // 21-17:  reserved - must be zero
	uint_t fa   :10;  // 31-22:  bits 31-22 of frame address
} pdem_f_t;

// union to allow easy switching back and forth
typedef union pde4k_u {
	pde_t    a;
	pdem_f_t f;
} pde4m_t;

// page table entries

// as a 32-bit word, in types.h
// typedef uint32_t pte_t;

// broken out into fields
typedef struct pte_s {
	uint_t p   :1;    // 0:  present
	uint_t rw  :1;    // 1:  writable
	uint_t us  :1;    // 2:  user/supervisor
	uint_t pwt :1;    // 3:  cache write-through
	uint_t pcd :1;    // 4:  cache disable
	uint_t a   :1;    // 5:  accessed
	uint_t d   :1;    // 6:  dirty
	uint_t pat :1;    // 7:  page attribute table in use
	uint_t g   :1;    // 8:  global
	uint_t avl :3;    // 11-9:  ignored (available)
	uint_t fa  :20;   // 31-12:  frame address
} ptef_t;

// union to allow easy switching back and forth
typedef union pte4k_u {
	pte_t    a;
	ptef_t   f;
} pte4k_t;

// page fault error code bits
// comment: meaning when 1 / meaning when 0
struct pfec_s {
	uint_t p    :1;		// page-level protection violation / !present
	uint_t w    :1;		// write / read
	uint_t us   :1;		// user-mode access / supervisor-mode access
	uint_t rsvd :1;		// reserved bit violation / not
	uint_t id   :1;		// instruction fetch / data fetch
	uint_t pk   :1;		// protection-key violation / !pk
	uint_t ss   :1;		// shadow stack access / !ss
	uint_t hlat :1;		// HLAT paging / ordinary paging or access rights
	uint_t xtr1 :7;		// unused
	uint_t sgz  :1;		// SGX-specific access control violation / !SGX
	uint_t xtr2 :16;	// more unused
};

// union to allow easy switching between 32-bit and field versions
typedef union pfec_u {
	uint32_t      a;
	struct pfec_s f;
} pfec_t;

// Mapping descriptor for VA::PA mappings
typedef struct mapping_t {
	uint32_t va_start;  // starting virtual address for this range
	uint32_t pa_start;  // first physical address in the range
	uint32_t pa_end;    // last physical address in the range
	uint32_t perm;      // access control
} mapping_t;

#endif  /* !ASM_SRC */

#endif
