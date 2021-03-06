"""
    rankdf(df, [rev])

Compute row ranks for a DataFrame and add bottom line with mean ranks.
Ties receive average rank. The columns of df are assigned to individual algorithms.
Rows of df are the individual experiments (e.g. datasets) across which we compare the 
algorithms.

rev (default true) - higher score is better
"""
function rankdf(df, rev = true)
    _df = deepcopy(df)
    nrows, ncols = size(_df)
    nalgs = ncols - 1

    algnames = names(df)[2:end]

    for i in 1:nrows
        row = _df[i,2:end]
        arow = reshape(permutedims(Vector(row)), nalgs)
        isort = sortperm(arow, rev = rev)
        j = 1
        tiec = 0 # tie counter
        # create ranks
        arow = collect(skipmissing(arow))
        for alg in algnames[isort]
            if ismissing(row[alg][1])
                _df[!,salg][i] = missing
            else
                # this decides ties
                val = row[alg][1]
                nties = size(arow[arow.==val],1) - 1
                if nties > 0
                    _df[!,alg][i] = (sum((j-tiec):(j+nties-tiec)))/(nties+1)
                    tiec +=1
                    # restart tie counter
                    if tiec > nties
                        tiec = 0
                    end
                else
                    _df[!,alg][i] = j
                end
                j+=1
            end
        end
    end

    # append the final row with mean ranks
    push!(_df, vcat(Array{Any}(["mean rank"]), zeros(nalgs)))
    for alg in algnames
        _df[!,alg][end] = Statistics.mean(_df[!,alg][1:end-1][.!isnan.(_df[!,alg][1:end-1])])
    end

    return _df
end
