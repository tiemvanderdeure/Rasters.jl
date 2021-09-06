
"""
    FileArray{X} <: DiskArrays.AbstractDiskArray

Filearray is a DiskArrays.jl `AbstractDiskArray`. Instead of holding
an open object, it just holds a filename string that is opened lazily 
when it needs to be read.
"""
struct FileArray{X,T,N,K,EC,HC} <: DiskArrays.AbstractDiskArray{T,N}
    filename::String
    size::NTuple{N,Int}
    key::K
    eachchunk::EC
    haschunks::HC
    write::Bool
end
function FileArray{X,T,N}(
    filename, size, key::K, eachchunk::EC=size, 
    haschunks::HC=DA.Unchunked(), write=false
) where {X,T,N,K,EC,HC}
    FileArray{X,T,N,K,EC,HC}(filename, size, key, eachchunk, haschunks, write)
end
function FileArray{X,T,N}(filename::String, size::Tuple; 
    key=nothing, eachchunk=size, haschunks=DA.Unchunked(), write=false
) where {X,T,N}
    FileArray{X,T,N}(filename, size, key, eachchunk, haschunks, write)
end

# FileArray has X, T and N parameters not recoverable from fields
ConstructionBase.constructorof(::Type{<:FileArray{X,T,N}}) where {X,T,N} = FileArray{X,T,N}

filename(A::FileArray) = A.filename
key(A::FileArray) = A.key
Base.size(A::FileArray) = A.size
DA.eachchunk(A::FileArray) = A.eachchunk
DA.haschunks(A::FileArray) = A.haschunks

# Run function `f` on the result of _open for the file type
function Base.open(f::Function, A::FileArray{X}; write=A.write, kw...) where X
    _open(f, X, filename(A); key=key(A), write, kw...)
end

DA.readblock!(A::FileArray, dst, r::AbstractUnitRange...) = open(o -> dst .= o[r...], A)
DA.writeblock!(A::FileArray, src, r::AbstractUnitRange...) = 
    open(o -> o[r...] .= src, A; write=A.write)


"""
    GeoDiskArray <: DiskArrays.AbstractDiskArray

A basic DiskArrays.jl wrapper for objects that don't have one defined yet. 
When we `open` a `FileArray` it is replaced with a `GeoDiskArray`.
"""
struct GeoDiskArray{X,T,N,V,EC,HC} <: DiskArrays.AbstractDiskArray{T,N}
    var::V
    eachchunk::EC
    haschunks::HC
end
function GeoDiskArray{X}(
    var::V, eachchunk=DA.eachchunk(var), haschunks=DA.haschunks(var)
) where {X,V}
    T = eltype(var)
    N = ndims(var)
    GeoDiskArray{X,T,N,V,typeof(eachchunk),typeof(haschunks)}(var, eachchunk, haschunks)
end

Base.parent(A::GeoDiskArray) = A.var
Base.size(A::GeoDiskArray{<:Any,T,N}) where {T,N} = size(parent(A))::NTuple{N,Int}

DA.haschunks(A::GeoDiskArray) = A.haschunks
DA.eachchunk(A::GeoDiskArray) = A.eachchunk
DA.readblock!(A::GeoDiskArray, aout, r::AbstractUnitRange...) = aout .= parent(A)[r...]
DA.writeblock!(A::GeoDiskArray, v, r::AbstractUnitRange...) = parent(A)[r...] .= v
