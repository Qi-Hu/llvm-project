// RUN: %libomptarget-compile-generic && \
// RUN: env LIBOMPTARGET_AMDGPU_MAX_ASYNC_COPY_BYTES=0 %libomptarget-run-generic | \
// RUN: %fcheck-generic -allow-empty
// REQUIRES: amdgcn-amd-amdhsa

#include <assert.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

const int magic_num = 7;

int main(int argc, char *argv[]) {
  const int N = 128;
  const int num_devices = omp_get_num_devices();

  // No target device, just return
  if (num_devices == 0) {
    printf("PASS\n");
    return 0;
  }

  const int src_device = 0;
  int dst_device = num_devices - 1;

  int length = N * sizeof(int);
  int *src_ptr = omp_target_alloc(length, src_device);
  int *dst_ptr = omp_target_alloc(length, dst_device);

  if (!src_ptr || !dst_ptr) {
    printf("FAIL\n");
    return 1;
  }

#pragma omp target teams distribute parallel for device(src_device)            \
    is_device_ptr(src_ptr)
  for (int i = 0; i < N; ++i) {
    src_ptr[i] = magic_num;
  }

  if (omp_target_memcpy(dst_ptr, src_ptr, length, 0, 0, dst_device,
                        src_device)) {
    printf("FAIL\n");
    return 1;
  }

  int *buffer = malloc(length);
  if (!buffer) {
    printf("FAIL\n");
    return 1;
  }

#pragma omp target teams distribute parallel for device(dst_device)            \
    map(from : buffer[0 : N]) is_device_ptr(dst_ptr)
  for (int i = 0; i < N; ++i) {
    buffer[i] = dst_ptr[i] + magic_num;
  }

  for (int i = 0; i < N; ++i)
    assert(buffer[i] == 2 * magic_num);

  printf("PASS\n");

  // Free host and device memory
  free(buffer);
  omp_target_free(src_ptr, src_device);
  omp_target_free(dst_ptr, dst_device);

  return 0;
}

// CHECK: PASS
