import Base
using FillArrays: Fill
# """
# A power measure is a product of a measure with itself. The number of elements in
# the product determines the dimensionality of the resulting support.

# Note that power measures are only well-defined for integer powers.

# The nth power of a measure μ can be written μ^x.
# """
# PowerMeasure{M,N,D} = ProductMeasure{Fill{M,N,D}}

export PowerMeasure

struct PowerMeasure{M,A} <: AbstractProductMeasure
    parent::M
    axes::A
end

function Pretty.tile(μ::PowerMeasure)
    sz = length.(μ.axes)
    arg1 = Pretty.tile(μ.parent)
    arg2 = Pretty.tile(length(sz) == 1 ? only(sz) : sz)
    return Pretty.pair_layout(arg1, arg2; sep = " ^ ")
end

function Base.rand(rng::AbstractRNG, ::Type{T}, d::PowerMeasure) where {T}
    map(CartesianIndices(d.axes)) do _
        rand(rng, T, d.parent)
    end
end

@inline function powermeasure(x::T, sz::Vararg{<:Integer,N}) where {T, N}
    a = axes(Fill{T, N}(x, sz))
    A = typeof(a)
    PowerMeasure{T,A}(x,a)
end

@inline function powermeasure(x::T, sz::Tuple{Vararg{<:Any,N}}) where {T, N}
    a = axes(Fill{T, N}(x, sz))
    A = typeof(a)
    PowerMeasure{T,A}(x,a)
end

marginals(d::PowerMeasure) = Fill(d.parent, d.axes)

Base.:^(μ::AbstractMeasure, dims) = powermeasure(μ, dims)

# Base.show(io::IO, d::PowerMeasure) = print(io, d.parent, " ^ ", size(d.xs))
# Base.show(io::IO, d::PowerMeasure{M,1}) where {M} = print(io, d.parent, " ^ ", length(d.xs))

# gentype(d::PowerMeasure{M,N}) where {M,N} = @inbounds Array{gentype(first(marginals(d))), N}

params(d::PowerMeasure) = params(first(marginals(d)))

# basemeasure(μ::PowerMeasure) = @inbounds basemeasure(first(μ.data))^size(μ.data)

@inline function basemeasure(d::PowerMeasure)
    basemeasure(d.parent) ^ d.axes
end

function basemeasure_depth(::PowerMeasure{M}) where {M}
    return basemeasure_depth(M)
end

function basemeasure_type(::Type{PowerMeasure{M,D}}) where {M,D}
    return PowerMeasure{basemeasure_type(M),D}
end

function basemeasure_depth(::Type{PowerMeasure{M,D}}) where {M<:PrimitiveMeasure,D}
    return static(0)
end

@inline function logdensity_def(d::PowerMeasure, x)
    sum(x) do xj
        logdensity_def(d.parent, xj)
    end
end
