"""
    loadtable(fname, datacols)

Load a csv file into DataFrame, reformatting specified data columnsto floats and missings.
"""
function loadtable(fname, datacols)
    #load the df
    data = CSV.read(fname)

    # round the nubmers and replace "missing" with actual missing values
    rounddf!(convertdf!(data, datacols), 6, datacols)

    return data
end

"""
    convertdf!(df, datacols)

Convert cells of df to floats or missings - specially crafted for dfs loaded from csvs.
"""
function convertdf!(df, datacols)
    nrows, ncols = size(df)

    # go through the whole df and replace missing strings with actual Missing type
    # and floats with float
    if typeof(datacols) == Int64
        cnames = names(df)[datacols:end]
    else
        cnames = names(df)[datacols]
    end

    for cname in cnames
        df[ismissing.(df[cname]), cname] = Inf
        df[cname] = Array{Any,1}(df[cname])
    end

    for cname in cnames
        for i in 1:nrows
            if df[cname][i] == Inf || df[cname][i] == "missing"
                df[cname][i]=missing
            elseif df[cname][i]=="NA"
                df[cname][i]=missing
            else 
               df[cname][i]=float(df[cname][i])
            end
        end
    end

    return df
end

"""
    convertdf(df, datacols)

Convert cells of df to floats or missings - specially crafted for dfs loaded from csvs.
"""
function convertdf(df, datacols)
    _df = deepcopy(df)
    return convertdf!(_df)
end

"""
   rounddf!(df, n, datacols)

Round values in datacols of df to n valid digits.
"""
function rounddf!(df, n, datacols)
    nrows, ncols = size(df)

    # go through the whole df and replace missing strings with actual Missing type
    # and floats with float
    if typeof(datacols) == Int64
        cnames = names(df)[datacols:end]
    else
        cnames = names(df)[datacols]
    end

    for cname in cnames
        for i in 1:nrows
            (ismissing(df[!,cname][i])) ? df[!,cname][i]=missing :
                df[!,cname][i]=round(float(df[!,cname][i]),digits=n)
        end
    end

    return df
end

"""
   rounddf(df, n, datacols)

Round values in datacols of df to n valid digits.
"""
function rounddf(df, n, datacols)
    _df = deepcopy(df)
    return rounddf!(_df, n, datacols)
end

"""
    eol(s)

Replaces the "& " at the end of s with a tabular end of line.
"""
function eol(s)
    return string(s[1:end-2], " \\\\ \n")
end

"""
    wspad(s, n)

Pads s with n white spaces.
"""
function wspad(s, n)
    return string(s, repeat(" ", n))
end

"""
    df2tex(df, caption=""; label="", pos = "h", align = "c";
           fitcolumn = false, lasthline = false, firstvline = false,
    asterisk = false, fittext=false, vertcolnames = false)

Convert DataFrame to a LaTex table.
"""
function df2tex(df, caption=""; label = "", pos = "h", align = "c",
    fitcolumn = false, lasthline = false, firstvline = false,
    asterisk = false, fittext=false, vertcolnames = false,
    column_aliases = nothing)
    @assert !(fitcolumn & fittext)
    cnames = names(df)
    nrows, ncols = size(df)

    # create the table beginning
    if asterisk
        s = "\\begin{table*}[$pos] \n "
    else
        s = "\\begin{table}[$pos] \n "
    end
    if fitcolumn
        s = string(s, "\\center \n \\resizebox{\\columnwidth}{!}{ \n \\begin{tabular}{")
    elseif fittext
        s = string(s, "\\center \n \\resizebox{\\textwidth}{!}{ \n \\begin{tabular}{")
    else
        s = string(s, "\\center \n \\begin{tabular}{")
    end
    for n in 1:ncols
        if firstvline && n == 1
            s = string(s, "$align | ")
        else
            s = string(s, "$align ")
        end
    end
    s = string(s,"} \n")

    # create the header
    s = wspad(s,2)
    for (i,name) in enumerate(names(df))
        # rename the columns if aliases are supplied
        col_label = isnothing(column_aliases) ? name : column_aliases[i] 
        if vertcolnames && i > 1
            s = string(s, "\\rotatebox{90}{$(col_label)} & ")
        else
            s = string(s, "$(col_label) & ")
        end
    end
    s = eol(s)
    s = wspad(s,2)
    s = string(s, "\\hline \n")

    # fill the table
    for i in 1:nrows
        s = wspad(s,2)
        for j in 1:ncols
            s = string(s, "$(df[i,j]) & ")
        end
        s= eol(s)
        if lasthline && i == nrows-1
            s = wspad(s,2)
            s = string(s, "\\hline\n")
        end
    end

    # create the table ending
    s = string(s, " \\end{tabular}\n")
    if fitcolumn || fittext
        s = string(s, " }\n")
    end
    if caption!=""
        s = string(s, " \\caption{$caption} \n")
    end
    if label!=""
        s = string(s, " \\label{$label} \n")
    end
    if asterisk
        s = string(s, "\\end{table*}")
    else
        s = string(s, "\\end{table}")
    end

    return s
end

"""
    string2file(f, s)

Save string s to file f.
"""
function string2file(f, s)
    open(f, "w") do _f
        write(_f, s)
    end
end

"""
    miss2hyphen!(df)

Replaces all missing values with a hyphen "--".
"""
function miss2hyphen!(df)
    nrows, ncols = size(df)

    for i in 1:nrows
        for j in 1:ncols
            if ismissing(df[i,j])
             df[i,j]="--"
            end
        end
    end

    return df
end

"""
    miss2hyphen(df)

Replaces all missing values with a hyphen "--".
"""
function miss2hyphen(df)
    _df = deepcopy(df)
    return miss2hyphen!(df)
end

"""
    rpaddf!(df,n)

Rightpad all numerical values with zeros to have n decimal digits.
"""
function rpaddf!(df,n)
    nrows, ncols = size(df)

    for i in 1:nrows
        for j in 1:ncols
            if typeof(df[i,j]) == String
                s = split("$(df[i,j])", ".")
                if length(s) > 1
                    df[i,j] = "$(s[1]).$(rpad(s[2],n,"0"))"
                end
            end
        end
    end

    return df
end

"""
    rpaddf(df,n)

Rightpad all numerical values with zeros to have n decimal digits.
"""
function rpaddf(df,n)
    _df = deepcopy(df)
    return rpaddf!(_df,n)
end

"""
    mergedfs(ldf, rdf)

Merges DataFrames for the article purpose.
"""
function mergedfs(ldf, rdf)
    nrows, ncols = size(ldf)
    @assert (nrows, ncols) == size(rdf)

    df = deepcopy(ldf)

    # first merge all cells
    for i in 1:nrows
        for j in 2:ncols
            df[i,j] = "$(df[i,j])($(rdf[i,j]))"
        end
    end

    return df
end

"""
    cols2string!(df)

Changes the type of all columns of a DataFrame to type string.    
"""
cols2string!(df) = map(x->df[!,x]=string.(df[!,x]), names(df))

"""
    cols2string(df)

Changes the type of all columns of a DataFrame to type string.    
"""
function cols2string(df) 
    _df = deepcopy(df)
    cols2string!(_df)
    return _df
end

"""
    round_string_rpad(df, ndecimal, cols)

Round a df, convert columns defined in cols to string and rpad with zeros.
"""
round_string_rpad(df, ndecimal, cols) = 
    PaperUtils.rpaddf(PaperUtils.cols2string(PaperUtils.rounddf(df, ndecimal, cols)), ndecimal)


"""
    shade_row(r)

Ignores the first element of the row. Then provides shading for the top 3 elements.
"""
function shade_row!(r; rev=false)
    levels = [45, 30, 15]
    valsf = Meta.parse.([x for x in r[2:end]])
    uvalsf = unique(valsf)
    sortinds = sortperm(uvalsf, rev=!rev)

    for (i, lvl) in zip(sortinds[1:min(length(sortinds), length(levels))], levels)
        inds = valsf .== uvalsf[i]
        for k in 1:length(inds)
            if inds[k]
                r[2:end][k] = "\\cellcolor{gray!$(lvl)} " * r[2:end][k]
            end
        end
    end
end

"""
    shade_rows!(df; last_rev=false)

Shade the top 3 results in row for all rows.
"""
function shade_rows!(df; last_rev=false)
    rows = eachrow(df)
    if last_rev
        map(shade_row!, rows[1:end-1])
        shade_row!(rows[end], rev=true)
    else
        map(shade_row!, rows)
    end
end

"""
    shade_rows(df; last_rev=false)

Shade the top 3 results in row for all rows.
"""
function shade_rows(df; kwargs...)
    _df = deepcopy(df)
    shade_rows!(_df; kwargs...)
    _df
end