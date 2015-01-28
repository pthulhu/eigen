// This file is part of Eigen, a lightweight C++ template library
// for linear algebra.
//
// Copyright (C) 2014 Benoit Steiner <benoit.steiner.goog@gmail.com>
//
// This Source Code Form is subject to the terms of the Mozilla
// Public License v. 2.0. If a copy of the MPL was not distributed
// with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef EIGEN_CXX11_TENSOR_TENSOR_FUNCTORS_H
#define EIGEN_CXX11_TENSOR_TENSOR_FUNCTORS_H

namespace Eigen {
namespace internal {

// Standard reduction functors
template <typename T> struct SumReducer
{
  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reduce(const T t, T* accum) const {
    (*accum) += t;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reducePacket(const Packet& p, Packet* accum) const {
    (*accum) = padd<Packet>(*accum, p);
  }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T initialize() const {
    return static_cast<T>(0);
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet initializePacket() const {
    return pset1<Packet>(0);
  }
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalize(const T accum) const {
    return accum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet finalizePacket(const Packet& vaccum) const {
    return vaccum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalizeBoth(const T saccum, const Packet& vaccum) const {
    return saccum + predux(vaccum);
  }
};

template <typename T> struct MeanReducer
{
  static const bool PacketAccess = true;
  MeanReducer() : scalarCount_(0), packetCount_(0) { }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reduce(const T t, T* accum) {
    (*accum) += t;
    scalarCount_++;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reducePacket(const Packet& p, Packet* accum) {
    (*accum) = padd<Packet>(*accum, p);
    packetCount_++;
  }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T initialize() const {
    return static_cast<T>(0);
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet initializePacket() const {
    return pset1<Packet>(0);
  }
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalize(const T accum) const {
    return accum / scalarCount_;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet finalizePacket(const Packet& vaccum) const {
    return pdiv(vaccum, pset1<Packet>(packetCount_));
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalizeBoth(const T saccum, const Packet& vaccum) const {
    return (saccum + predux(vaccum)) / (scalarCount_ + packetCount_ * packet_traits<Packet>::size);
  }

  protected:
    int scalarCount_;
    int packetCount_;
};

template <typename T> struct MaxReducer
{
  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reduce(const T t, T* accum) const {
    if (t > *accum) { *accum = t; }
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reducePacket(const Packet& p, Packet* accum) const {
    (*accum) = pmax<Packet>(*accum, p);
  }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T initialize() const {
    return -(std::numeric_limits<T>::max)();
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet initializePacket() const {
    return pset1<Packet>(-(std::numeric_limits<T>::max)());
  }
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalize(const T accum) const {
    return accum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet finalizePacket(const Packet& vaccum) const {
    return vaccum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalizeBoth(const T saccum, const Packet& vaccum) const {
    return (std::max)(saccum, predux_max(vaccum));
  }
};

template <typename T> struct MinReducer
{
  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reduce(const T t, T* accum) const {
    if (t < *accum) { *accum = t; }
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reducePacket(const Packet& p, Packet* accum) const {
    (*accum) = pmin<Packet>(*accum, p);
  }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T initialize() const {
    return (std::numeric_limits<T>::max)();
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet initializePacket() const {
    return pset1<Packet>((std::numeric_limits<T>::max)());
  }
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalize(const T accum) const {
    return accum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet finalizePacket(const Packet& vaccum) const {
    return vaccum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalizeBoth(const T saccum, const Packet& vaccum) const {
    return (std::min)(saccum, predux_min(vaccum));
  }
};


template <typename T> struct ProdReducer
{
  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reduce(const T t, T* accum) const {
    (*accum) *= t;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE void reducePacket(const Packet& p, Packet* accum) const {
    (*accum) = pmul<Packet>(*accum, p);
  }

  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T initialize() const {
    return static_cast<T>(1);
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet initializePacket() const {
    return pset1<Packet>(1);
  }
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalize(const T accum) const {
    return accum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE Packet finalizePacket(const Packet& vaccum) const {
    return vaccum;
  }
  template <typename Packet>
  EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T finalizeBoth(const T saccum, const Packet& vaccum) const {
    return saccum * predux_mul(vaccum);
  }
};

#if !defined (EIGEN_USE_GPU) || !defined(__CUDACC__) || !defined(__CUDA_ARCH__)
// We're not compiling a cuda kernel
template <typename T> struct UniformRandomGenerator {

  static const bool PacketAccess = true;

  template<typename Index>
  T operator()(Index, Index = 0) const {
    return random<T>();
  }
  template<typename Index>
  typename internal::packet_traits<T>::type packetOp(Index, Index = 0) const {
    const int packetSize = internal::packet_traits<T>::size;
    EIGEN_ALIGN_DEFAULT T values[packetSize];
    for (int i = 0; i < packetSize; ++i) {
      values[i] = random<T>();
    }
    return internal::pload<typename internal::packet_traits<T>::type>(values);
  }
};

#else

// We're compiling a cuda kernel
template <typename T> struct UniformRandomGenerator;

template <> struct UniformRandomGenerator<float> {

  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC UniformRandomGenerator() {
    const int tid = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(0, tid, 0, &m_state);
  }

  template<typename Index> EIGEN_DEVICE_FUNC
  float operator()(Index, Index = 0) const {
    return curand_uniform(&m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  float4 packetOp(Index, Index = 0) const {
    return curand_uniform4(&m_state);
  }

 private:
  mutable curandStatePhilox4_32_10_t m_state;
};

template <> struct UniformRandomGenerator<double> {

  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC UniformRandomGenerator() {
    const int tid = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(0, tid, 0, &m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  double operator()(Index, Index = 0) const {
    return curand_uniform_double(&m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  double2 packetOp(Index, Index = 0) const {
    return curand_uniform2_double(&m_state);
  }

 private:
  mutable curandStatePhilox4_32_10_t m_state;
};

#endif


#if (!defined (EIGEN_USE_GPU) || !defined(__CUDACC__) || !defined(__CUDA_ARCH__)) && __cplusplus > 199711
// We're not compiling a cuda kernel
template <typename T> struct NormalRandomGenerator {

  static const bool PacketAccess = true;

  NormalRandomGenerator() : m_distribution(0, 1) {}
  NormalRandomGenerator(const NormalRandomGenerator& other) : m_distribution(other.m_distribution) { }

  template<typename Index>
  T operator()(Index, Index = 0) const {
    return m_distribution(m_generator);
  }
  template<typename Index>
  typename internal::packet_traits<T>::type packetOp(Index, Index = 0) const {
    const int packetSize = internal::packet_traits<T>::size;
    EIGEN_ALIGN_DEFAULT T values[packetSize];
    for (int i = 0; i < packetSize; ++i) {
      values[i] = m_distribution(m_generator);
    }
    return internal::pload<typename internal::packet_traits<T>::type>(values);
  }

  mutable std::normal_distribution<T> m_distribution;
  mutable std::default_random_engine m_generator;
};

#elif defined (EIGEN_USE_GPU) && defined(__CUDACC__) && defined(__CUDA_ARCH__)

// We're compiling a cuda kernel
template <typename T> struct NormalRandomGenerator;

template <> struct NormalRandomGenerator<float> {

  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC NormalRandomGenerator() {
    const int tid = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(0, tid, 0, &m_state);
  }

  template<typename Index> EIGEN_DEVICE_FUNC
  float operator()(Index, Index = 0) const {
    return curand_normal(&m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  float4 packetOp(Index, Index = 0) const {
    return curand_normal4(&m_state);
  }

 private:
  mutable curandStatePhilox4_32_10_t m_state;
};

template <> struct NormalRandomGenerator<double> {

  static const bool PacketAccess = true;

  EIGEN_DEVICE_FUNC NormalRandomGenerator() {
    const int tid = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(0, tid, 0, &m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  double operator()(Index, Index = 0) const {
    return curand_normal_double(&m_state);
  }
  template<typename Index> EIGEN_DEVICE_FUNC
  double2 packetOp(Index, Index = 0) const {
    return curand_normal2_double(&m_state);
  }

 private:
  mutable curandStatePhilox4_32_10_t m_state;
};

#endif


} // end namespace internal
} // end namespace Eigen

#endif // EIGEN_CXX11_TENSOR_TENSOR_FUNCTORS_H
