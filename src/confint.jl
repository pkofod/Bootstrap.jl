abstract ConfIntMethod

const _level = 0.95

"""
Basic Confidence Interval

```julia
BasicConfInt(0.95)
```

"""
type BasicConfInt <: ConfIntMethod
    level::AbstractFloat
end

BasicConfInt() = BasicConfInt(_level)


"""
Percentile Confidence Interval

```julia
PercentileConfInt(0.95)
```

"""
type PercentileConfInt <: ConfIntMethod
    level::AbstractFloat
end

PercentileConfInt() = PercentileConfInt(_level)

type NormalConfInt <: ConfIntMethod
    level::AbstractFloat
end


"""
Normal Confidence Interval

```julia
NormalConfInt(0.95)
```

"""
NormalConfInt() = NormalConfInt(_level)

type BCaConfInt <: ConfIntMethod
    level::AbstractFloat
    ## quantile method
end


"""
Bias-Corrected and Accelerated (BCa) Confidence Interval

```julia
BCaConfInt(0.95)
```

"""
BCaConfInt() = BCaConfInt(_level)

type StudentConfInt <: ConfIntMethod
    level::AbstractFloat
end

"""
Student's Confidence Interval

```julia
StudentConfInt(0.95)
```

"""
StudentConfInt() = StudentConfInt(_level)

level(cim::ConfIntMethod) = cim.level

function ci(bs::BootstrapSample, cim::ConfIntMethod)
    tuple([ci(bs, cim, i) for i in 1:nvar(bs)]...)
end

## basic
function ci(bs::BootstrapSample, cim::BasicConfInt, i::Int)
    l = level(cim)
    t0 = original(bs, i)
    t1 = straps(bs, i)
    alpha = ([l, -l] + 1)/2
    lower, upper = 2 * t0 - quantile(t1, alpha)
    return t0, lower, upper
end

## percentile
function ci(bs::BootstrapSample, cim::PercentileConfInt, i::Int)
    l = level(cim)
    t0 = original(bs, i)
    t1 = straps(bs, i)
    alpha = ([-l, l] + 1)/2
    lower, upper = quantile(t1, alpha)
    return t0, lower, upper
end

## normal
function ci(bs::BootstrapSample, cim::NormalConfInt, i::Int)
    l = level(cim)
    t0 = original(bs, i)
    t0b = t0 - bias(bs, i)
    merr = se(bs, i) * quantile(Normal(), (1+l)/2)
    lower = t0b - merr
    upper = t0b + merr
    return t0, lower, upper
end

## BCa
function ci(bs::BootstrapSample, cim::BCaConfInt, i::Int)
    l = level(cim)
    t0 = original(bs, i)
    t1 = straps(bs, i)
    n = length(t1)
    alpha = ([-l, l] + 1)/2
    z0 = quantile(Normal(), mean(t1 .< t0))
    jkt = jack_knife_estimate(data(bs), statistic(bs), i)
    resid = (n-1) .* (t0 - jkt)
    a = sum(resid.^3) / (6.*(sum(resid.^2)).^(1.5))
    qn = quantile(Normal(), alpha)
    z1 = z0 + qn
    zalpha = cdf(Normal(), z0 + (z1) ./ (1-a*(z1)))
    lower, upper = quantile(t1, zalpha)
    return t0, lower, upper
end


## student
function ci(bs::BootstrapSample, sd1::AbstractVector{Float64}, cim::StudentConfInt, i::Int)
    l = level(cim)
    t0 = original(bs, i)
    t1 = straps(bs, i)
    t0se = se(bs, i)
    z = (t1 - t0) ./ sd1
    alpha = ([l, -l] + 1.)/2.
    lower, upper = t0 - t0se .* quantile(z, alpha)
    return t0, lower, upper
end

const _conf_int_methods =
    [BasicConfInt,
     PercentileConfInt,
     NormalConfInt,
     BCaConfInt,
     StudentConfInt]
