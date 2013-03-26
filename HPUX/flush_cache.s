; flush_cache.s
;
; Routine to flush and synchronize data and instruction caches
; for dynamic loading
;
; Copyright Hewlett-Packard Co. 1985,1991
;
; All HP VARs and HP customers have a non-exclusive royalty-free license
; to copy and use this flush_cashe() routine in source code and/or object
; code.

       .code

; flush_cache(addr, len) - executes FDC and FIC instructions for every
; cache line in the text region given by starting addr and len.  When done,
; it executes a SYNC instruction and then enough NOPs to assure the cache
; has been flushed.
;
; Assumption: Cache line size is at least 16 bytes.  Seven NOPs is enough
; to assure cache has been flushed.  This routine is called to flush the
; cache for just-loaded dynamically linked code which will be executed
; from SR5 (data) space.

; %arg0=GR26, %arg1=GR25, %arg2=GR24, %arg3=GR23, %sr0=SR0.
; loop1 flushes data cache.  arg0 holds address.  arg1 holds offset.
; SR=0 means that SID of data area is used for fdc.
; loop2 flushes inst cache.  arg2 holds address.  arg3 holds offset.
; SR=sr0 means that SID of data area is used for fic.
; fdc x(0,y) -> 0 means use SID of data area.
; fic x(%sr0,y) -> SR0 means use SR0 SID (which is set to data area).

        .proc
        .callinfo
        .export flush_cache,entry
flush_cache
        .enter
        ldsid   (0,%arg0),%r1           ; Extract SID (SR5) from address
        mtsp    %r1,%sr0                ; SID -> SR0
        ldo     -1(%arg1),%arg1         ; offset = length -1
        copy    %arg0,%arg2             ; Copy address from GR26 to GR24
        copy    %arg1,%arg3             ; Copy offset from GR25 to GR23

        fdc     %arg1(0,%arg0)          ; Flush data cache @SID.address+offset
loop1   addib,>,n       -16,%arg1,loop1 ; Decrement offset by cache line size
        fdc     %arg1(0,%arg0)          ; Flush data cache @SID.address+offset
        ; flush first word at addr, to handle arbitrary cache line boundary
        fdc     0(0,%arg0)
        sync

        fic     %arg3(%sr0,%arg2)       ; Flush inst cache @SID.address+offset
loop2   addib,>,n       -16,%arg3,loop2 ; Decrement offset by cache line size
        fic     %arg3(%sr0,%arg2)       ; Flush inst cache @SID.address+offset
        ; flush first word at addr, to handle arbitrary cache line boundary
        fic     0(%sr0,%arg2)

        sync
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        .leave
        .procend
        .end
