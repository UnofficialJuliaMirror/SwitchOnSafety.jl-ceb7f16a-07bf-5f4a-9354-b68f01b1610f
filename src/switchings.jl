import Base.start, Base.done, Base.next

type SwitchingSequence
    s::DiscreteSwitchedSystem
    A::AbstractMatrix
    seq::Vector{Int}
end

type SwitchingIterator
    s::DiscreteSwitchedSystem
    k::Int
    v0::Int
    forward::Bool
end

function switchings(s::DiscreteSwitchedSystem, k::Int, v0::Int, forward=true)
    SwitchingIterator(s, k, v0, forward)
end

function modes(s::DiscreteSwitchedSystem, v, forward=true)
    1:length(s.A)
end

function matrixfor(s::DiscreteSwitchedSystem, mode)
    s.A[mode]
end

function state(s::DiscreteSwitchedSystem, mode, forward=true)
    1
end

nextinnode(s, v, u) = u+1
doneinnode(s, v, u) = u >= length(s.A)
nextoutnode(s, v, u) = u+1
doneoutnode(s, v, u) = u >= length(s.A)

function start(it::SwitchingIterator)
    k = it.k
    seq = Vector{Int}(k)
    I = it.forward ? (1:k) : (k:-1:1)
    v = it.v0
    A = speye(dim(it.s))
    As = Vector{eltype(it.s.A)}(k)
    modeit = Vector{Any}(k)
    modest = Vector{Any}(k)
    for i in I
        modeit[i] = v == -1 ? (1:0) : modes(it.s, v, it.forward)
        modest[i] = start(modeit[i])
        if done(modeit[i], modest[i])
            v = -1
        elseif i != last(I)
            seq[i], modest[i] = next(modeit[i], modest[i])
            As[i] = matrixfor(it.s, seq[i]) * A
            A = As[i]
            v = state(it.s, seq[i], it.forward)
        end
    end
    (modeit, modest, As, seq)
end
function done(it::SwitchingIterator, st)
    modeit, modest, _, _ = st
    I = it.forward ? (it.k:-1:1) : (1:it.k)
    for i in I
        if !done(modeit[i], modest[i])
            return false
        end
    end
    true
end
function next(it::SwitchingIterator, st)
    modeit, modest, As, seq = st
    I = it.forward ? (it.k:-1:1) : (1:it.k)
    i = -1
    for j in I
        if !done(modeit[j], modest[j])
            i = j
            break
        end
    end
    inc = it.forward ? 1 : -1
    prev = i - inc
    A = (prev >= 1 && prev <= it.k) ? As[prev] : speye(dim(it.s))
    while i > 0 && i <= it.k
        seq[i], modest[i] = next(modeit[i], modest[i])
        As[i] = matrixfor(it.s, seq[i]) * A
        A = As[i]
        v = state(it.s, seq[i], it.forward)
        i += inc
        if i > 0 && i <= it.k
            modeit[i], modest[i] = modes(it.s, v, it.forward)
        end
    end
    (SwitchingSequence(it.s, A, copy(seq)), (modeit, modest, As, seq))
end