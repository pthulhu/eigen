// This file is part of Eigen, a lightweight C++ template library
// for linear algebra.
//
// Copyright (C) 2014 Benoit Steiner <benoit.steiner.goog@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla
// Public License v. 2.0. If a copy of the MPL was not distributed
// with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

#define EIGEN_TEST_NO_LONGDOUBLE
#define EIGEN_TEST_NO_COMPLEX
#define EIGEN_TEST_FUNC cxx11_tensor_cuda
#define EIGEN_DEFAULT_DENSE_INDEX_TYPE int
#define EIGEN_USE_GPU


#include "main.h"
#include <unsupported/Eigen/CXX11/Tensor>

using Eigen::Tensor;

void test_cuda_elementwise_small() {
  Tensor<float, 1> in1(Eigen::array<int, 1>(2));
  Tensor<float, 1> in2(Eigen::array<int, 1>(2));
  Tensor<float, 1> out(Eigen::array<int, 1>(2));
  in1.setRandom();
  in2.setRandom();

  std::size_t in1_bytes = in1.size() * sizeof(float);
  std::size_t in2_bytes = in2.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_in1;
  float* d_in2;
  float* d_out;
  cudaMalloc((void**)(&d_in1), in1_bytes);
  cudaMalloc((void**)(&d_in2), in2_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_in1, in1.data(), in1_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_in2, in2.data(), in2_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 1>, Eigen::Aligned> gpu_in1(
      d_in1, Eigen::array<int, 1>(2));
  Eigen::TensorMap<Eigen::Tensor<float, 1>, Eigen::Aligned> gpu_in2(
      d_in2, Eigen::array<int, 1>(2));
  Eigen::TensorMap<Eigen::Tensor<float, 1>, Eigen::Aligned> gpu_out(
      d_out, Eigen::array<int, 1>(2));

  gpu_out.device(gpu_device) = gpu_in1 + gpu_in2;

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost,
                         gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 2; ++i) {
    VERIFY_IS_APPROX(
        out(Eigen::array<int, 1>(i)),
        in1(Eigen::array<int, 1>(i)) + in2(Eigen::array<int, 1>(i)));
  }

  cudaFree(d_in1);
  cudaFree(d_in2);
  cudaFree(d_out);
}

void test_cuda_elementwise()
{
  Tensor<float, 3> in1(Eigen::array<int, 3>(72,53,97));
  Tensor<float, 3> in2(Eigen::array<int, 3>(72,53,97));
  Tensor<float, 3> in3(Eigen::array<int, 3>(72,53,97));
  Tensor<float, 3> out(Eigen::array<int, 3>(72,53,97));
  in1.setRandom();
  in2.setRandom();
  in3.setRandom();

  std::size_t in1_bytes = in1.size() * sizeof(float);
  std::size_t in2_bytes = in2.size() * sizeof(float);
  std::size_t in3_bytes = in3.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_in1;
  float* d_in2;
  float* d_in3;
  float* d_out;
  cudaMalloc((void**)(&d_in1), in1_bytes);
  cudaMalloc((void**)(&d_in2), in2_bytes);
  cudaMalloc((void**)(&d_in3), in3_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_in1, in1.data(), in1_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_in2, in2.data(), in2_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_in3, in3.data(), in3_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 3> > gpu_in1(d_in1, Eigen::array<int, 3>(72,53,97));
  Eigen::TensorMap<Eigen::Tensor<float, 3> > gpu_in2(d_in2, Eigen::array<int, 3>(72,53,97));
  Eigen::TensorMap<Eigen::Tensor<float, 3> > gpu_in3(d_in3, Eigen::array<int, 3>(72,53,97));
  Eigen::TensorMap<Eigen::Tensor<float, 3> > gpu_out(d_out, Eigen::array<int, 3>(72,53,97));

  gpu_out.device(gpu_device) = gpu_in1 + gpu_in2 * gpu_in3;

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 72; ++i) {
    for (int j = 0; j < 53; ++j) {
      for (int k = 0; k < 97; ++k) {
        VERIFY_IS_APPROX(out(Eigen::array<int, 3>(i,j,k)), in1(Eigen::array<int, 3>(i,j,k)) + in2(Eigen::array<int, 3>(i,j,k)) * in3(Eigen::array<int, 3>(i,j,k)));
      }
    }
  }

  cudaFree(d_in1);
  cudaFree(d_in2);
  cudaFree(d_in3);
  cudaFree(d_out);
}

void test_cuda_reduction()
{
  Tensor<float, 4> in1(72,53,97,113);
  Tensor<float, 2> out(72,97);
  in1.setRandom();

  std::size_t in1_bytes = in1.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_in1;
  float* d_out;
  cudaMalloc((void**)(&d_in1), in1_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_in1, in1.data(), in1_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4> > gpu_in1(d_in1, 72,53,97,113);
  Eigen::TensorMap<Eigen::Tensor<float, 2> > gpu_out(d_out, 72,97);

  array<int, 2> reduction_axis;
  reduction_axis[0] = 1;
  reduction_axis[1] = 3;

  gpu_out.device(gpu_device) = gpu_in1.maximum(reduction_axis);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 72; ++i) {
    for (int j = 0; j < 97; ++j) {
      float expected = 0;
      for (int k = 0; k < 53; ++k) {
        for (int l = 0; l < 113; ++l) {
          expected =
              std::max<float>(expected, in1(i, k, j, l));
        }
      }
      VERIFY_IS_APPROX(out(i,j), expected);
    }
  }

  cudaFree(d_in1);
  cudaFree(d_out);
}

template<int DataLayout>
void test_cuda_contraction()
{
  // with these dimensions, the output has 300 * 140 elements, which is
  // more than 30 * 1024, which is the number of threads in blocks on
  // a 15 SM GK110 GPU
  Tensor<float, 4, DataLayout> t_left(6, 50, 3, 31);
  Tensor<float, 5, DataLayout> t_right(Eigen::array<int, 5>(3, 31, 7, 20, 1));
  Tensor<float, 5, DataLayout> t_result(Eigen::array<int, 5>(6, 50, 7, 20, 1));

  t_left.setRandom();
  t_right.setRandom();

  std::size_t t_left_bytes = t_left.size()  * sizeof(float);
  std::size_t t_right_bytes = t_right.size() * sizeof(float);
  std::size_t t_result_bytes = t_result.size() * sizeof(float);

  float* d_t_left;
  float* d_t_right;
  float* d_t_result;

  cudaMalloc((void**)(&d_t_left), t_left_bytes);
  cudaMalloc((void**)(&d_t_right), t_right_bytes);
  cudaMalloc((void**)(&d_t_result), t_result_bytes);

  cudaMemcpy(d_t_left, t_left.data(), t_left_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_t_right, t_right.data(), t_right_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4, DataLayout> > gpu_t_left(d_t_left, 6, 50, 3, 31);
  Eigen::TensorMap<Eigen::Tensor<float, 5, DataLayout> > gpu_t_right(d_t_right, 3, 31, 7, 20, 1);
  Eigen::TensorMap<Eigen::Tensor<float, 5, DataLayout> > gpu_t_result(d_t_result, 6, 50, 7, 20, 1);

  typedef Eigen::Map<Eigen::Matrix<float, Dynamic, Dynamic, DataLayout> > MapXf;
  MapXf m_left(t_left.data(), 300, 93);
  MapXf m_right(t_right.data(), 93, 140);
  Eigen::Matrix<float, Dynamic, Dynamic, DataLayout> m_result(300, 140);

  typedef Tensor<float, 1>::DimensionPair DimPair;
  Eigen::array<DimPair, 2> dims;
  dims[0] = DimPair(2, 0);
  dims[1] = DimPair(3, 1);

  m_result = m_left * m_right;
  gpu_t_result.device(gpu_device) = gpu_t_left.contract(gpu_t_right, dims);

  cudaMemcpy(t_result.data(), d_t_result, t_result_bytes, cudaMemcpyDeviceToHost);

  for (size_t i = 0; i < t_result.dimensions().TotalSize(); i++) {
    if (fabs(t_result.data()[i] - m_result.data()[i]) >= 1e-4) {
      std::cout << "mismatch detected at index " << i << ": " << t_result.data()[i] << " vs " <<  m_result.data()[i] << std::endl;
      assert(false);
    }
  }

  cudaFree(d_t_left);
  cudaFree(d_t_right);
  cudaFree(d_t_result);
}

template<int DataLayout>
void test_cuda_convolution_1d()
{
  Tensor<float, 4, DataLayout> input(74,37,11,137);
  Tensor<float, 1, DataLayout> kernel(4);
  Tensor<float, 4, DataLayout> out(74,34,11,137);
  input = input.constant(10.0f) + input.random();
  kernel = kernel.constant(7.0f) + kernel.random();

  std::size_t input_bytes = input.size() * sizeof(float);
  std::size_t kernel_bytes = kernel.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_input;
  float* d_kernel;
  float* d_out;
  cudaMalloc((void**)(&d_input), input_bytes);
  cudaMalloc((void**)(&d_kernel), kernel_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_input, input.data(), input_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_kernel, kernel.data(), kernel_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4, DataLayout> > gpu_input(d_input, 74,37,11,137);
  Eigen::TensorMap<Eigen::Tensor<float, 1, DataLayout> > gpu_kernel(d_kernel, 4);
  Eigen::TensorMap<Eigen::Tensor<float, 4, DataLayout> > gpu_out(d_out, 74,34,11,137);

  Eigen::array<int, 1> dims(1);
  gpu_out.device(gpu_device) = gpu_input.convolve(gpu_kernel, dims);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 74; ++i) {
    for (int j = 0; j < 34; ++j) {
      for (int k = 0; k < 11; ++k) {
        for (int l = 0; l < 137; ++l) {
          const float result = out(i,j,k,l);
          const float expected = input(i,j+0,k,l) * kernel(0) + input(i,j+1,k,l) * kernel(1) +
                                 input(i,j+2,k,l) * kernel(2) + input(i,j+3,k,l) * kernel(3);
          VERIFY_IS_APPROX(result, expected);
        }
      }
    }
  }

  cudaFree(d_input);
  cudaFree(d_kernel);
  cudaFree(d_out);
}

void test_cuda_convolution_inner_dim_col_major_1d()
{
  Tensor<float, 4, ColMajor> input(74,9,11,7);
  Tensor<float, 1, ColMajor> kernel(4);
  Tensor<float, 4, ColMajor> out(71,9,11,7);
  input = input.constant(10.0f) + input.random();
  kernel = kernel.constant(7.0f) + kernel.random();

  std::size_t input_bytes = input.size() * sizeof(float);
  std::size_t kernel_bytes = kernel.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_input;
  float* d_kernel;
  float* d_out;
  cudaMalloc((void**)(&d_input), input_bytes);
  cudaMalloc((void**)(&d_kernel), kernel_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_input, input.data(), input_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_kernel, kernel.data(), kernel_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4, ColMajor> > gpu_input(d_input,74,9,11,7);
  Eigen::TensorMap<Eigen::Tensor<float, 1, ColMajor> > gpu_kernel(d_kernel,4);
  Eigen::TensorMap<Eigen::Tensor<float, 4, ColMajor> > gpu_out(d_out,71,9,11,7);

  Eigen::array<int, 1> dims(0);
  gpu_out.device(gpu_device) = gpu_input.convolve(gpu_kernel, dims);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 71; ++i) {
    for (int j = 0; j < 9; ++j) {
      for (int k = 0; k < 11; ++k) {
        for (int l = 0; l < 7; ++l) {
          const float result = out(i,j,k,l);
          const float expected = input(i+0,j,k,l) * kernel(0) + input(i+1,j,k,l) * kernel(1) +
                                 input(i+2,j,k,l) * kernel(2) + input(i+3,j,k,l) * kernel(3);
          VERIFY_IS_APPROX(result, expected);
        }
      }
    }
  }

  cudaFree(d_input);
  cudaFree(d_kernel);
  cudaFree(d_out);
}

void test_cuda_convolution_inner_dim_row_major_1d()
{
  Tensor<float, 4, RowMajor> input(7,9,11,74);
  Tensor<float, 1, RowMajor> kernel(4);
  Tensor<float, 4, RowMajor> out(7,9,11,71);
  input = input.constant(10.0f) + input.random();
  kernel = kernel.constant(7.0f) + kernel.random();

  std::size_t input_bytes = input.size() * sizeof(float);
  std::size_t kernel_bytes = kernel.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_input;
  float* d_kernel;
  float* d_out;
  cudaMalloc((void**)(&d_input), input_bytes);
  cudaMalloc((void**)(&d_kernel), kernel_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_input, input.data(), input_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_kernel, kernel.data(), kernel_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4, RowMajor> > gpu_input(d_input, 7,9,11,74);
  Eigen::TensorMap<Eigen::Tensor<float, 1, RowMajor> > gpu_kernel(d_kernel, 4);
  Eigen::TensorMap<Eigen::Tensor<float, 4, RowMajor> > gpu_out(d_out, 7,9,11,71);

  Eigen::array<int, 1> dims(3);
  gpu_out.device(gpu_device) = gpu_input.convolve(gpu_kernel, dims);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 7; ++i) {
    for (int j = 0; j < 9; ++j) {
      for (int k = 0; k < 11; ++k) {
        for (int l = 0; l < 71; ++l) {
          const float result = out(i,j,k,l);
          const float expected = input(i,j,k,l+0) * kernel(0) + input(i,j,k,l+1) * kernel(1) +
                                 input(i,j,k,l+2) * kernel(2) + input(i,j,k,l+3) * kernel(3);
          VERIFY_IS_APPROX(result, expected);
        }
      }
    }
  }

  cudaFree(d_input);
  cudaFree(d_kernel);
  cudaFree(d_out);
}

template<int DataLayout>
void test_cuda_convolution_2d()
{
  Tensor<float, 4, DataLayout> input(74,37,11,137);
  Tensor<float, 2, DataLayout> kernel(3,4);
  Tensor<float, 4, DataLayout> out(74,35,8,137);
  input = input.constant(10.0f) + input.random();
  kernel = kernel.constant(7.0f) + kernel.random();

  std::size_t input_bytes = input.size() * sizeof(float);
  std::size_t kernel_bytes = kernel.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_input;
  float* d_kernel;
  float* d_out;
  cudaMalloc((void**)(&d_input), input_bytes);
  cudaMalloc((void**)(&d_kernel), kernel_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_input, input.data(), input_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_kernel, kernel.data(), kernel_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 4, DataLayout> > gpu_input(d_input,74,37,11,137);
  Eigen::TensorMap<Eigen::Tensor<float, 2, DataLayout> > gpu_kernel(d_kernel,3,4);
  Eigen::TensorMap<Eigen::Tensor<float, 4, DataLayout> > gpu_out(d_out,74,35,8,137);

  Eigen::array<int, 2> dims(1,2);
  gpu_out.device(gpu_device) = gpu_input.convolve(gpu_kernel, dims);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 74; ++i) {
    for (int j = 0; j < 35; ++j) {
      for (int k = 0; k < 8; ++k) {
        for (int l = 0; l < 137; ++l) {
          const float result = out(i,j,k,l);
          const float expected = input(i,j+0,k+0,l) * kernel(0,0) +
                                 input(i,j+1,k+0,l) * kernel(1,0) +
                                 input(i,j+2,k+0,l) * kernel(2,0) +
                                 input(i,j+0,k+1,l) * kernel(0,1) +
                                 input(i,j+1,k+1,l) * kernel(1,1) +
                                 input(i,j+2,k+1,l) * kernel(2,1) +
                                 input(i,j+0,k+2,l) * kernel(0,2) +
                                 input(i,j+1,k+2,l) * kernel(1,2) +
                                 input(i,j+2,k+2,l) * kernel(2,2) +
                                 input(i,j+0,k+3,l) * kernel(0,3) +
                                 input(i,j+1,k+3,l) * kernel(1,3) +
                                 input(i,j+2,k+3,l) * kernel(2,3);
          VERIFY_IS_APPROX(result, expected);
        }
      }
    }
  }

  cudaFree(d_input);
  cudaFree(d_kernel);
  cudaFree(d_out);
}

template<int DataLayout>
void test_cuda_convolution_3d()
{
  Tensor<float, 5, DataLayout> input(Eigen::array<int, 5>(74,37,11,137,17));
  Tensor<float, 3, DataLayout> kernel(3,4,2);
  Tensor<float, 5, DataLayout> out(Eigen::array<int, 5>(74,35,8,136,17));
  input = input.constant(10.0f) + input.random();
  kernel = kernel.constant(7.0f) + kernel.random();

  std::size_t input_bytes = input.size() * sizeof(float);
  std::size_t kernel_bytes = kernel.size() * sizeof(float);
  std::size_t out_bytes = out.size() * sizeof(float);

  float* d_input;
  float* d_kernel;
  float* d_out;
  cudaMalloc((void**)(&d_input), input_bytes);
  cudaMalloc((void**)(&d_kernel), kernel_bytes);
  cudaMalloc((void**)(&d_out), out_bytes);

  cudaMemcpy(d_input, input.data(), input_bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_kernel, kernel.data(), kernel_bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;    
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<float, 5, DataLayout> > gpu_input(d_input,74,37,11,137,17);
  Eigen::TensorMap<Eigen::Tensor<float, 3, DataLayout> > gpu_kernel(d_kernel,3,4,2);
  Eigen::TensorMap<Eigen::Tensor<float, 5, DataLayout> > gpu_out(d_out,74,35,8,136,17);

  Eigen::array<int, 3> dims(1,2,3);
  gpu_out.device(gpu_device) = gpu_input.convolve(gpu_kernel, dims);

  assert(cudaMemcpyAsync(out.data(), d_out, out_bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 74; ++i) {
    for (int j = 0; j < 35; ++j) {
      for (int k = 0; k < 8; ++k) {
        for (int l = 0; l < 136; ++l) {
          for (int m = 0; m < 17; ++m) {
            const float result = out(i,j,k,l,m);
            const float expected = input(i,j+0,k+0,l+0,m) * kernel(0,0,0) +
                                   input(i,j+1,k+0,l+0,m) * kernel(1,0,0) +
                                   input(i,j+2,k+0,l+0,m) * kernel(2,0,0) +
                                   input(i,j+0,k+1,l+0,m) * kernel(0,1,0) +
                                   input(i,j+1,k+1,l+0,m) * kernel(1,1,0) +
                                   input(i,j+2,k+1,l+0,m) * kernel(2,1,0) +
                                   input(i,j+0,k+2,l+0,m) * kernel(0,2,0) +
                                   input(i,j+1,k+2,l+0,m) * kernel(1,2,0) +
                                   input(i,j+2,k+2,l+0,m) * kernel(2,2,0) +
                                   input(i,j+0,k+3,l+0,m) * kernel(0,3,0) +
                                   input(i,j+1,k+3,l+0,m) * kernel(1,3,0) +
                                   input(i,j+2,k+3,l+0,m) * kernel(2,3,0) +
                                   input(i,j+0,k+0,l+1,m) * kernel(0,0,1) +
                                   input(i,j+1,k+0,l+1,m) * kernel(1,0,1) +
                                   input(i,j+2,k+0,l+1,m) * kernel(2,0,1) +
                                   input(i,j+0,k+1,l+1,m) * kernel(0,1,1) +
                                   input(i,j+1,k+1,l+1,m) * kernel(1,1,1) +
                                   input(i,j+2,k+1,l+1,m) * kernel(2,1,1) +
                                   input(i,j+0,k+2,l+1,m) * kernel(0,2,1) +
                                   input(i,j+1,k+2,l+1,m) * kernel(1,2,1) +
                                   input(i,j+2,k+2,l+1,m) * kernel(2,2,1) +
                                   input(i,j+0,k+3,l+1,m) * kernel(0,3,1) +
                                   input(i,j+1,k+3,l+1,m) * kernel(1,3,1) +
                                   input(i,j+2,k+3,l+1,m) * kernel(2,3,1);
            VERIFY_IS_APPROX(result, expected);
          }
        }
      }
    }
  }

  cudaFree(d_input);
  cudaFree(d_kernel);
  cudaFree(d_out);
}


template <typename Scalar>
void test_cuda_lgamma(const Scalar stddev)
{
  Tensor<Scalar, 2> in(72,97);
  in.setRandom();
  in *= in.constant(stddev);
  Tensor<Scalar, 2> out(72,97);
  out.setZero();

  std::size_t bytes = in.size() * sizeof(Scalar);

  Scalar* d_in;
  Scalar* d_out;
  cudaMalloc((void**)(&d_in), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_in, in.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_in(d_in, 72, 97);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_out(d_out, 72, 97);

  gpu_out.device(gpu_device) = gpu_in.lgamma();

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 72; ++i) {
    for (int j = 0; j < 97; ++j) {
      VERIFY_IS_APPROX(out(i,j), (std::lgamma)(in(i,j)));
    }
  }

  cudaFree(d_in);
  cudaFree(d_out);
}

template <typename Scalar>
void test_cuda_digamma()
{
  Tensor<Scalar, 1> in(7);
  Tensor<Scalar, 1> out(7);
  Tensor<Scalar, 1> expected_out(7);
  out.setZero();

  in(0) = Scalar(1);
  in(1) = Scalar(1.5);
  in(2) = Scalar(4);
  in(3) = Scalar(-10.5);
  in(4) = Scalar(10000.5);
  in(5) = Scalar(0);
  in(6) = Scalar(-1);

  expected_out(0) = Scalar(-0.5772156649015329);
  expected_out(1) = Scalar(0.03648997397857645);
  expected_out(2) = Scalar(1.2561176684318);
  expected_out(3) = Scalar(2.398239129535781);
  expected_out(4) = Scalar(9.210340372392849);
  expected_out(5) = std::numeric_limits<Scalar>::infinity();
  expected_out(6) = std::numeric_limits<Scalar>::infinity();

  std::size_t bytes = in.size() * sizeof(Scalar);

  Scalar* d_in;
  Scalar* d_out;
  cudaMalloc((void**)(&d_in), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_in, in.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 1> > gpu_in(d_in, 7);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 1> > gpu_out(d_out, 7);

  gpu_out.device(gpu_device) = gpu_in.digamma();

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 5; ++i) {
    VERIFY_IS_APPROX(out(i), expected_out(i));
  }
  for (int i = 5; i < 7; ++i) {
    VERIFY_IS_EQUAL(out(i), expected_out(i));
  }
}

template <typename Scalar>
void test_cuda_igamma()
{
  Tensor<Scalar, 2> a(6, 6);
  Tensor<Scalar, 2> x(6, 6);
  Tensor<Scalar, 2> out(6, 6);
  out.setZero();

  Scalar a_s[] = {Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)};
  Scalar x_s[] = {Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)};

  for (int i = 0; i < 6; ++i) {
    for (int j = 0; j < 6; ++j) {
      a(i, j) = a_s[i];
      x(i, j) = x_s[j];
    }
  }

  Scalar nan = std::numeric_limits<Scalar>::quiet_NaN();
  Scalar igamma_s[][6] = {{0.0, nan, nan, nan, nan, nan},
                          {0.0, 0.6321205588285578, 0.7768698398515702,
                           0.9816843611112658, 9.999500016666262e-05, 1.0},
                          {0.0, 0.4275932955291202, 0.608374823728911,
                           0.9539882943107686, 7.522076445089201e-07, 1.0},
                          {0.0, 0.01898815687615381, 0.06564245437845008,
                           0.5665298796332909, 4.166333347221828e-18, 1.0},
                          {0.0, 0.9999780593618628, 0.9999899967080838,
                           0.9999996219837988, 0.9991370418689945, 1.0},
                          {0.0, 0.0, 0.0, 0.0, 0.0, 0.5042041932513908}};



  std::size_t bytes = a.size() * sizeof(Scalar);

  Scalar* d_a;
  Scalar* d_x;
  Scalar* d_out;
  cudaMalloc((void**)(&d_a), bytes);
  cudaMalloc((void**)(&d_x), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_a, a.data(), bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_x, x.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_a(d_a, 6, 6);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_x(d_x, 6, 6);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_out(d_out, 6, 6);

  gpu_out.device(gpu_device) = gpu_a.igamma(gpu_x);

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 6; ++i) {
    for (int j = 0; j < 6; ++j) {
      if ((std::isnan)(igamma_s[i][j])) {
        VERIFY((std::isnan)(out(i, j)));
      } else {
        VERIFY_IS_APPROX(out(i, j), igamma_s[i][j]);
      }
    }
  }
}

template <typename Scalar>
void test_cuda_igammac()
{
  Tensor<Scalar, 2> a(6, 6);
  Tensor<Scalar, 2> x(6, 6);
  Tensor<Scalar, 2> out(6, 6);
  out.setZero();

  Scalar a_s[] = {Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)};
  Scalar x_s[] = {Scalar(0), Scalar(1), Scalar(1.5), Scalar(4), Scalar(0.0001), Scalar(1000.5)};

  for (int i = 0; i < 6; ++i) {
    for (int j = 0; j < 6; ++j) {
      a(i, j) = a_s[i];
      x(i, j) = x_s[j];
    }
  }

  Scalar nan = std::numeric_limits<Scalar>::quiet_NaN();
  Scalar igammac_s[][6] = {{nan, nan, nan, nan, nan, nan},
                           {1.0, 0.36787944117144233, 0.22313016014842982,
                            0.018315638888734182, 0.9999000049998333, 0.0},
                           {1.0, 0.5724067044708798, 0.3916251762710878,
                            0.04601170568923136, 0.9999992477923555, 0.0},
                           {1.0, 0.9810118431238462, 0.9343575456215499,
                            0.4334701203667089, 1.0, 0.0},
                           {1.0, 2.1940638138146658e-05, 1.0003291916285e-05,
                            3.7801620118431334e-07, 0.0008629581310054535,
                            0.0},
                           {1.0, 1.0, 1.0, 1.0, 1.0, 0.49579580674813944}};

  std::size_t bytes = a.size() * sizeof(Scalar);

  Scalar* d_a;
  Scalar* d_x;
  Scalar* d_out;
  cudaMalloc((void**)(&d_a), bytes);
  cudaMalloc((void**)(&d_x), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_a, a.data(), bytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_x, x.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_a(d_a, 6, 6);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_x(d_x, 6, 6);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_out(d_out, 6, 6);

  gpu_out.device(gpu_device) = gpu_a.igammac(gpu_x);

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 6; ++i) {
    for (int j = 0; j < 6; ++j) {
      if ((std::isnan)(igammac_s[i][j])) {
        VERIFY((std::isnan)(out(i, j)));
      } else {
        VERIFY_IS_APPROX(out(i, j), igammac_s[i][j]);
      }
    }
  }
}

template <typename Scalar>
void test_cuda_erf(const Scalar stddev)
{
  Tensor<Scalar, 2> in(72,97);
  in.setRandom();
  in *= in.constant(stddev);
  Tensor<Scalar, 2> out(72,97);
  out.setZero();

  std::size_t bytes = in.size() * sizeof(Scalar);

  Scalar* d_in;
  Scalar* d_out;
  cudaMalloc((void**)(&d_in), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_in, in.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_in(d_in, 72, 97);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_out(d_out, 72, 97);

  gpu_out.device(gpu_device) = gpu_in.erf();

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 72; ++i) {
    for (int j = 0; j < 97; ++j) {
      VERIFY_IS_APPROX(out(i,j), (std::erf)(in(i,j)));
    }
  }

  cudaFree(d_in);
  cudaFree(d_out);
}

template <typename Scalar>
void test_cuda_erfc(const Scalar stddev)
{
  Tensor<Scalar, 2> in(72,97);
  in.setRandom();
  in *= in.constant(stddev);
  Tensor<Scalar, 2> out(72,97);
  out.setZero();

  std::size_t bytes = in.size() * sizeof(Scalar);

  Scalar* d_in;
  Scalar* d_out;
  cudaMalloc((void**)(&d_in), bytes);
  cudaMalloc((void**)(&d_out), bytes);

  cudaMemcpy(d_in, in.data(), bytes, cudaMemcpyHostToDevice);

  Eigen::CudaStreamDevice stream;
  Eigen::GpuDevice gpu_device(&stream);

  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_in(d_in, 72, 97);
  Eigen::TensorMap<Eigen::Tensor<Scalar, 2> > gpu_out(d_out, 72, 97);

  gpu_out.device(gpu_device) = gpu_in.erfc();

  assert(cudaMemcpyAsync(out.data(), d_out, bytes, cudaMemcpyDeviceToHost, gpu_device.stream()) == cudaSuccess);
  assert(cudaStreamSynchronize(gpu_device.stream()) == cudaSuccess);

  for (int i = 0; i < 72; ++i) {
    for (int j = 0; j < 97; ++j) {
      VERIFY_IS_APPROX(out(i,j), (std::erfc)(in(i,j)));
    }
  }

  cudaFree(d_in);
  cudaFree(d_out);
}

void test_cxx11_tensor_cuda()
{
  CALL_SUBTEST_1(test_cuda_elementwise_small());
  CALL_SUBTEST_1(test_cuda_elementwise());
  CALL_SUBTEST_1(test_cuda_reduction());
  CALL_SUBTEST_2(test_cuda_contraction<ColMajor>());
  CALL_SUBTEST_2(test_cuda_contraction<RowMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_1d<ColMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_1d<RowMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_inner_dim_col_major_1d());
  CALL_SUBTEST_3(test_cuda_convolution_inner_dim_row_major_1d());
  CALL_SUBTEST_3(test_cuda_convolution_2d<ColMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_2d<RowMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_3d<ColMajor>());
  CALL_SUBTEST_3(test_cuda_convolution_3d<RowMajor>());

#if __cplusplus > 199711L
  // std::erf, std::erfc, and so on where only added in c++11. We use them
  // as a golden reference to validate the results produced by Eigen. Therefore
  // we can only run these tests if we use a c++11 compiler.
  CALL_SUBTEST_4(test_cuda_lgamma<float>(1.0f));
  CALL_SUBTEST_4(test_cuda_lgamma<float>(100.0f));
  CALL_SUBTEST_4(test_cuda_lgamma<float>(0.01f));
  CALL_SUBTEST_4(test_cuda_lgamma<float>(0.001f));

  CALL_SUBTEST_4(test_cuda_digamma<float>());


  CALL_SUBTEST_4(test_cuda_erf<float>(1.0f));
  CALL_SUBTEST_4(test_cuda_erf<float>(100.0f));
  CALL_SUBTEST_4(test_cuda_erf<float>(0.01f));
  CALL_SUBTEST_4(test_cuda_erf<float>(0.001f));

  CALL_SUBTEST_4(test_cuda_erfc<float>(1.0f));
  // CALL_SUBTEST(test_cuda_erfc<float>(100.0f));
  CALL_SUBTEST_4(test_cuda_erfc<float>(5.0f)); // CUDA erfc lacks precision for large inputs
  CALL_SUBTEST_4(test_cuda_erfc<float>(0.01f));
  CALL_SUBTEST_4(test_cuda_erfc<float>(0.001f));

  CALL_SUBTEST_4(test_cuda_lgamma<double>(1.0));
  CALL_SUBTEST_4(test_cuda_lgamma<double>(100.0));
  CALL_SUBTEST_4(test_cuda_lgamma<double>(0.01));
  CALL_SUBTEST_4(test_cuda_lgamma<double>(0.001));

  CALL_SUBTEST_4(test_cuda_digamma<double>());

  CALL_SUBTEST_4(test_cuda_erf<double>(1.0));
  CALL_SUBTEST_4(test_cuda_erf<double>(100.0));
  CALL_SUBTEST_4(test_cuda_erf<double>(0.01));
  CALL_SUBTEST_4(test_cuda_erf<double>(0.001));

  CALL_SUBTEST_4(test_cuda_erfc<double>(1.0));
  // CALL_SUBTEST(test_cuda_erfc<double>(100.0));
  CALL_SUBTEST_4(test_cuda_erfc<double>(5.0)); // CUDA erfc lacks precision for large inputs
  CALL_SUBTEST_4(test_cuda_erfc<double>(0.01));
  CALL_SUBTEST_4(test_cuda_erfc<double>(0.001));

  CALL_SUBTEST_5(test_cuda_igamma<float>());
  CALL_SUBTEST_5(test_cuda_igammac<float>());

  CALL_SUBTEST_5(test_cuda_igamma<double>());
  CALL_SUBTEST_5(test_cuda_igammac<double>());
#endif
}
