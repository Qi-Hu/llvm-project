; RUN: llc -mtriple=amdgcn < %s | FileCheck -enable-var-scope -check-prefixes=GCN,O2 %s
; RUN: llc -O0 -mtriple=amdgcn < %s | FileCheck -enable-var-scope -check-prefix=GCN %s

; GCN-LABEL: {{^}}zext_grp_size_128:
; GCN-NOT: and_b32
define amdgpu_kernel void @zext_grp_size_128(ptr addrspace(1) nocapture %arg) #0 {
bb:
  %tmp = tail call i32 @llvm.amdgcn.workitem.id.x()
  %tmp1 = and i32 %tmp, 127
  store i32 %tmp1, ptr addrspace(1) %arg, align 4
  %tmp2 = tail call i32 @llvm.amdgcn.workitem.id.y()
  %tmp3 = and i32 %tmp2, 127
  %tmp4 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 1
  store i32 %tmp3, ptr addrspace(1) %tmp4, align 4
  %tmp5 = tail call i32 @llvm.amdgcn.workitem.id.z()
  %tmp6 = and i32 %tmp5, 127
  %tmp7 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 2
  store i32 %tmp6, ptr addrspace(1) %tmp7, align 4
  ret void
}

; GCN-LABEL: {{^}}zext_grp_size_32x4x1:
; GCN-NOT: and_b32
define amdgpu_kernel void @zext_grp_size_32x4x1(ptr addrspace(1) nocapture %arg) #0 !reqd_work_group_size !0 {
bb:
  %tmp = tail call i32 @llvm.amdgcn.workitem.id.x()
  %tmp1 = and i32 %tmp, 31
  store i32 %tmp1, ptr addrspace(1) %arg, align 4
  %tmp2 = tail call i32 @llvm.amdgcn.workitem.id.y()
  %tmp3 = and i32 %tmp2, 3
  %tmp4 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 1
  store i32 %tmp3, ptr addrspace(1) %tmp4, align 4
  %tmp5 = tail call i32 @llvm.amdgcn.workitem.id.z()
  %tmp6 = and i32 %tmp5, 1
  %tmp7 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 2
  store i32 %tmp6, ptr addrspace(1) %tmp7, align 4
  ret void
}

; GCN-LABEL: {{^}}zext_grp_size_1x1x1:
; GCN-NOT: and_b32

; When EarlyCSE is not run this call produces a range max with 0 active bits,
; which is a special case as an AssertZext from width 0 is invalid.
define amdgpu_kernel void @zext_grp_size_1x1x1(ptr addrspace(1) nocapture %arg) #0 !reqd_work_group_size !1 {
  %tmp = tail call i32 @llvm.amdgcn.workitem.id.x()
  %tmp1 = and i32 %tmp, 1
  store i32 %tmp1, ptr addrspace(1) %arg, align 4
  ret void
}

; GCN-LABEL: {{^}}zext_grp_size_512:
; GCN-NOT: and_b32
define amdgpu_kernel void @zext_grp_size_512(ptr addrspace(1) nocapture %arg) #1 {
bb:
  %tmp = tail call i32 @llvm.amdgcn.workitem.id.x()
  %tmp1 = and i32 %tmp, 65535
  store i32 %tmp1, ptr addrspace(1) %arg, align 4
  %tmp2 = tail call i32 @llvm.amdgcn.workitem.id.y()
  %tmp3 = and i32 %tmp2, 65535
  %tmp4 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 1
  store i32 %tmp3, ptr addrspace(1) %tmp4, align 4
  %tmp5 = tail call i32 @llvm.amdgcn.workitem.id.z()
  %tmp6 = and i32 %tmp5, 65535
  %tmp7 = getelementptr inbounds i32, ptr addrspace(1) %arg, i64 2
  store i32 %tmp6, ptr addrspace(1) %tmp7, align 4
  ret void
}

; GCN-LABEL: {{^}}func_test_workitem_id_x_known_max_range:
; O2-NOT: and_b32
; O2: v_and_b32_e32 v{{[0-9]+}}, 0x3ff,
; O2-NOT: and_b32
define void @func_test_workitem_id_x_known_max_range(ptr addrspace(1) nocapture %out) #0 {
entry:
  %id = tail call i32 @llvm.amdgcn.workitem.id.x()
  %and = and i32 %id, 1023
  store i32 %and, ptr addrspace(1) %out, align 4
  ret void
}

; GCN-LABEL: {{^}}func_test_workitem_id_x_default_range:
; O2-NOT: and_b32
; O2: v_and_b32_e32 v{{[0-9]+}}, 0x3ff,
; O2-NOT: and_b32
define void @func_test_workitem_id_x_default_range(ptr addrspace(1) nocapture %out) #4 {
entry:
  %id = tail call i32 @llvm.amdgcn.workitem.id.x()
  %and = and i32 %id, 1023
  store i32 %and, ptr addrspace(1) %out, align 4
  ret void
}

declare i32 @llvm.amdgcn.workitem.id.x() #2

declare i32 @llvm.amdgcn.workitem.id.y() #2

declare i32 @llvm.amdgcn.workitem.id.z() #2

attributes #0 = { nounwind "amdgpu-flat-work-group-size"="64,128" }
attributes #1 = { nounwind "amdgpu-flat-work-group-size"="512,512" }
attributes #2 = { nounwind readnone speculatable }
attributes #3 = { nounwind readnone }
attributes #4 = { nounwind }

!0 = !{i32 32, i32 4, i32 1}
!1 = !{i32 1, i32 1, i32 1}
