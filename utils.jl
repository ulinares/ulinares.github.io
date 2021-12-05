function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits = 2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return pagevar("index", var)
end

function lx_baz(com, _)
    # keep this first line
    brace_content = Franklin.content(com.braces[1]) # input string
    # do whatever you want here
    return uppercase(brace_content)
end

"""
    {{blogposts}}
Plug in the list of blog posts contained in the `/blog/` folder.
"""
function hfun_blogposts(path_to_scan)
    curyear = year(Dates.today())
    path_to_scan = path_to_scan[1]
    io = IOBuffer()
    for year = curyear:-1:2021
        ys = "$year"
        year < curyear && write(io, "\n**$year**\n")
        for month = 12:-1:1
            ms = "0"^(month < 10) * "$month"
            base = joinpath(path_to_scan, ys, ms)
            isdir(base) || continue
            posts = filter!(p -> endswith(p, ".md"), readdir(base))
            days = zeros(Int, length(posts))
            lines = Vector{String}(undef, length(posts))
            for (i, post) in enumerate(posts)
                ps = splitext(post)[1]
                url = "/$path_to_scan/$ys/$ms/$ps/"
                surl = strip(url, '/')
                title = pagevar(surl, :title)
                title === nothing && (title = "Untitled")
                pubdate = pagevar(surl, :published)
                if isnothing(pubdate)
                    date = "$ys-$ms-01"
                    days[i] = 1
                else
                    date = Date(pubdate, dateformat"d U Y")
                    days[i] = day(date)
                end
                lines[i] = "\n[$title]($url) $date \n"
            end
            # sort by day
            foreach(line -> write(io, line), lines[sortperm(days, rev = true)])
        end
    end
    # markdown conversion adds `<p>` beginning and end but
    # we want to  avoid this to avoid an empty separator
    r = Franklin.fd2html(String(take!(io)), internal = true)
    return r
end


function hfun_list_projects()
    io = IOBuffer()
    projects_files_list = filter!(p -> endswith(p, ".md"), readdir("projects"))
    lines = Vector{String}(undef, length(projects_files_list))
    for (i, proj) in enumerate(projects_files_list)
        proj_s = splitext(proj)[1]
        url = "/projects/$(proj_s)"
        surl = strip(url, '/')
        title = pagevar(surl, :title)
        title === nothing && (title = "Untitled")
        date = pagevar(surl, :published)
        if isnothing(date)
            date = today()
        end
        lines[i] = "\n[$title]($url) $date \n"
    end
    foreach(line -> write(io, line), lines)
    r = Franklin.fd2html(String(take!(io)), internal = true)
end
