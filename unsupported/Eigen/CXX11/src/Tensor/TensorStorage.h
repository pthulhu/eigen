// This file is part of Eigen, a lightweight C++ template library
// for linear algebra.
//
// Copyright (C) 2013 Christian Seiler <christian@iwakd.de>
//
// This Source Code Form is subject to the terms of the Mozilla
// Public License v. 2.0. If a copy of the MPL was not distributed
// with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef EIGEN_CXX11_TENSOR_TENSORSTORAGE_H
#define EIGEN_CXX11_TENSOR_TENSORSTORAGE_H

#ifdef EIGEN_TENSOR_STORAGE_CTOR_PLUGIN
  #define EIGEN_INTERNAL_TENSOR_STORAGE_CTOR_PLUGIN EIGEN_TENSOR_STORAGE_CTOR_PLUGIN;
#else
  #define EIGEN_INTERNAL_TENSOR_STORAGE_CTOR_PLUGIN
#endif

namespace Eigen {

/** \internal
  *
  * \class TensorStorage
  * \ingroup CXX11_Tensor_Module
  *
  * \brief Stores the data of a tensor
  *
  * This class stores the data of fixed-size, dynamic-size or mixed tensors
  * in a way as compact as possible.
  *
  * \sa Tensor
  */
template<typename T, DenseIndex NumIndices_, DenseIndex Size, int Options_, typename Dimensions = void> class TensorStorage;


// Pure fixed-size storage
template<typename T, DenseIndex NumIndices_, DenseIndex Size, int Options_, typename FixedDimensions>
class TensorStorage
{
 private:
  EIGEN_ALIGN_DEFAULT T m_data[Size];
  FixedDimensions m_dimensions;

 public:
  EIGEN_DEVICE_FUNC
  EIGEN_STRONG_INLINE TensorStorage() {
    EIGEN_STATIC_ASSERT(Size == FixedDimensions::total_size, YOU_MADE_A_PROGRAMMING_MISTAKE)
  }

  EIGEN_DEVICE_FUNC
  EIGEN_STRONG_INLINE T *data() { return m_data; }
  EIGEN_DEVICE_FUNC
  EIGEN_STRONG_INLINE const T *data() const { return m_data; }

  EIGEN_DEVICE_FUNC
  EIGEN_STRONG_INLINE const FixedDimensions& dimensions() const { return m_dimensions; }

  EIGEN_DEVICE_FUNC
  EIGEN_STRONG_INLINE DenseIndex size() const { return m_dimensions.TotalSize(); }
};



// pure-dynamic, but without specification of all dimensions explicitly
template<typename T, DenseIndex NumIndices_, int Options_>
class TensorStorage<T, NumIndices_, Dynamic, Options_, void>
  : public TensorStorage<T, NumIndices_, Dynamic, Options_, typename internal::gen_numeric_list_repeated<DenseIndex, NumIndices_, Dynamic>::type>
{
  typedef TensorStorage<T, NumIndices_, Dynamic, Options_, typename internal::gen_numeric_list_repeated<DenseIndex, NumIndices_, Dynamic>::type> Base_;

  public:
    TensorStorage() { }
    TensorStorage(const TensorStorage<T, NumIndices_, Dynamic, Options_, void>& other) : Base_(other) { }

    TensorStorage(internal::constructor_without_unaligned_array_assert) : Base_(internal::constructor_without_unaligned_array_assert()) {}
    TensorStorage(DenseIndex size, const array<DenseIndex, NumIndices_>& dimensions) : Base_(size, dimensions) {}

  //      TensorStorage<T, NumIndices_, Dynamic, Options_, void>& operator=(const TensorStorage<T, NumIndices_, Dynamic, Options_, void>&) = default;
};

// pure dynamic
template<typename T, DenseIndex NumIndices_, int Options_>
class TensorStorage<T, NumIndices_, Dynamic, Options_, typename internal::gen_numeric_list_repeated<DenseIndex, NumIndices_, Dynamic>::type>
{
    T *m_data;
    DSizes<DenseIndex, NumIndices_> m_dimensions;

    typedef TensorStorage<T, NumIndices_, Dynamic, Options_, typename internal::gen_numeric_list_repeated<DenseIndex, NumIndices_, Dynamic>::type> Self_;
  public:
    TensorStorage() : m_data(0), m_dimensions() {}
    TensorStorage(internal::constructor_without_unaligned_array_assert)
      : m_data(0), m_dimensions(internal::template repeat<NumIndices_, DenseIndex>(0)) {}
    TensorStorage(DenseIndex size, const array<DenseIndex, NumIndices_>& dimensions)
        : m_data(internal::conditional_aligned_new_auto<T,(Options_&DontAlign)==0>(size)), m_dimensions(dimensions)
      { EIGEN_INTERNAL_TENSOR_STORAGE_CTOR_PLUGIN }
      TensorStorage(const Self_& other)
      : m_data(internal::conditional_aligned_new_auto<T,(Options_&DontAlign)==0>(internal::array_prod(other.m_dimensions)))
      , m_dimensions(other.m_dimensions)
    {
      internal::smart_copy(other.m_data, other.m_data+internal::array_prod(other.m_dimensions), m_data);
    }
    Self_& operator=(const Self_& other)
    {
      if (this != &other) {
        Self_ tmp(other);
        this->swap(tmp);
      }
      return *this;
    }

    ~TensorStorage() { internal::conditional_aligned_delete_auto<T,(Options_&DontAlign)==0>(m_data, internal::array_prod(m_dimensions)); }
    void swap(Self_& other)
    { std::swap(m_data,other.m_data); std::swap(m_dimensions,other.m_dimensions); }

    EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE const DSizes<DenseIndex, NumIndices_>& dimensions() const {return m_dimensions;}

    EIGEN_DEVICE_FUNC void resize(DenseIndex size, const array<DenseIndex, NumIndices_>& nbDimensions)
    {
      const DenseIndex currentSz = internal::array_prod(m_dimensions);
      if(size != currentSz)
      {
        internal::conditional_aligned_delete_auto<T,(Options_&DontAlign)==0>(m_data, currentSz);
        if (size)
          m_data = internal::conditional_aligned_new_auto<T,(Options_&DontAlign)==0>(size);
        else
          m_data = 0;
        EIGEN_INTERNAL_DENSE_STORAGE_CTOR_PLUGIN
      }
      m_dimensions = nbDimensions;
    }

    EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE T *data() { return m_data; }
    EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE const T *data() const { return m_data; }

    EIGEN_DEVICE_FUNC EIGEN_STRONG_INLINE DenseIndex size() const { return m_dimensions.TotalSize(); }
};

} // end namespace Eigen

#endif // EIGEN_CXX11_TENSOR_TENSORSTORAGE_H
