########################################################################################################################
###                                                     Packages                                                     ###
########################################################################################################################
using Dash
using DashHtmlComponents
using DashCoreComponents
using DashCytoscape
using DashTable
using JSON
using LightGraphs
using LinearAlgebra

########################################################################################################################
###                                                     Auxiliary                                                    ###
########################################################################################################################
#! Inverse Key-Value Function
function reverselookup(d, v)
    for k in keys(d)
        if d[k] == v
            return(k)
        end
    end
    error("Failed to reverse the Key-Value pair.")
end

########################################################################################################################
###                                                     Variables                                                    ###
########################################################################################################################
#! Default Graph Elements
graphElements = [
    Dict("data" => Dict("id" => "v4", "label" => "4"),
    "position" => Dict("x" => 0, "y" => 200)),
    Dict("data" => Dict("id" => "v5", "label" => "5"),
    "position" => Dict("x" => 100, "y" => 200)),
    Dict("data" => Dict("id" => "v1", "label" => "1"),
    "position" => Dict("x" => 0, "y" => 100)),
    Dict("data" => Dict("id" => "v2", "label" => "2"),
    "position" => Dict("x" => 100, "y" => 100)),
    Dict("data" => Dict("id" => "v3", "label" => "3"),
    "position" => Dict("x" => 50, "y" => 25)),
    Dict("data" => Dict("id" => "e12", "source" => "v1", "target" => "v2"),),
    Dict("data" => Dict("id" => "e14", "source" => "v1", "target" => "v4"),),
    Dict("data" => Dict("id" => "e13", "source" => "v1", "target" => "v3"),),
    Dict("data" => Dict("id" => "e23", "source" => "v2", "target" => "v3"),),
    Dict("data" => Dict("id" => "e25", "source" => "v2", "target" => "v5"),),
    Dict("data" => Dict("id" => "e45", "source" => "v4", "target" => "v5"),)
    ]

########################################################################################################################
###                                                  Initialization                                                  ###
########################################################################################################################
app = dash(external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"],
suppress_callback_exceptions = true)

########################################################################################################################
###                                                      Layout                                                      ###
########################################################################################################################
app.layout = html_div(style = Dict("maxWidth" => "100%",)) do
    #! Header
    html_header(style = Dict("maxWidth" => "100%")) do
        html_img(src = "https://i.imgur.com/3Xw9SYD.png",
            style = Dict("display" => "block", "maxWidth" => "100%",
            "height" => "auto", "marginLeft" => "auto", "marginRight" => "auto"))
        end,
    #! Body
    dcc_tabs(id = "Tabs", value = "Tab1") do
        dcc_tab(label="Slide 1", value = "Tab1"),
        dcc_tab(label="Slide 2", value = "Tab2")
    end,
    #! Selected Slide
    html_div(id = "selectedTab"),
    #! Empty Dash DataTable Box
    #? Due to a bug, you need to declare a dash_datatable in the initial layout.
    #? See: https://github.com/plotly/dash/issues/1010
    html_div() do 
        html_div(id = "dashtableContent"),
        dcc_location(id = "dashtableLocation", refresh = false),
        html_div(dash_datatable(id = "dtInitial"), style = Dict("display" => "none"))
    end,
    #! Footer
    html_footer() do 
        html_br(),
        html_img(src = "https://i.creativecommons.org/l/by/4.0/88x31.png",
        style = Dict("display" => "inline", "align" => "textRight",
        "verticalAlign" => "middle", "paddingRight" => 5)),
        html_div("Copyleft. All rights reversed. XIII Jornada
        de Iniciação Científica da Escola Nacional de Ciência Estatísticas (ENCE).",
        style = Dict("display" => "inline", "textAlign" => "justify"))
    end
end

########################################################################################################################
###                                             Callback: Selected Slide                                             ###
########################################################################################################################
#! Slide Selection
callback!(app,
Output("selectedTab", "children"),
Input("Tabs", "value")) do value
    #! Tab 1
    if value == "Tab1"
        return(
            html_div() do
                #! Column 1
                html_div(className = "five columns", style = Dict("display" => "flex",
                "border" => "2px solid", "height" => "840px", "borderRadius" => "25px", "width" => "30%",
                "marginTop" => "15px", "flexDirection" => "column", "marginLeft" => "5px")) do
                    #! Input: Refresh Info
                    html_div(html_button("Refresh", id = "refreshInfo",
                    style = Dict("fontWeight" => "bold", "fontSize" => "14px")),
                    style = Dict("display" => "block",
                    "padding" => "10px", "marginLeft" => "auto",
                    "marginRight" => "auto", "width" => "auto")),
                    #! Input: Graph Property
                    html_div(style = Dict("display" => "block", "padding" => "10px", "fontWeight" => "bold")) do
                        dcc_dropdown(id = "propertySelection",
                        options = [
                            (label = "Adjacency Matrix", value = "selectAdjMatrix"),
                            (label = "Laplacian Matrix", value = "selectLapMatrix"),
                            (label = "Eigenvalues", value = "selectAlgCon"),
                            (label = "Fiedler's Vector", value = "selectFiedler"),
                            (label = "Reliability", value = "selectReliability")
                            ],
                        value = "selectAdjMatrix")
                    end,
                    #! Output: Interactive DataTable
                    html_div(id = "graphTabOutput",
                    style = Dict("textAlign" => "center", "padding" => "1px",
                    "fontWeight" => "bold", "fontSize" => "20px"))
                end,
                #! Column 2
                html_div(className = "seven columns", style = Dict("display" => "flex",
                "width" => "65%", "flexDirection" => "column")) do
                    #! Input: Graph Manipulation
                    html_div([
                        html_button("Add Vertex",
                        id = "addVtx", n_clicks = nothing,
                        style = Dict("fontWeight" => "bold", "fontSize" => "14px")),
                        html_button("Remove Vertex",
                        id = "removeVtx", n_clicks = nothing,
                        style = Dict("fontWeight" => "bold", "fontSize" => "14px")),
                        html_button("Add Edge",
                        id = "addEdg", n_clicks = nothing,
                        style = Dict("fontWeight" => "bold", "fontSize" => "14px")),
                        html_button("Remove Edge",
                        id = "removeEdg", n_clicks = nothing,
                        style = Dict("fontWeight" => "bold", "fontSize" => "14px"))
                        ],
                    style = Dict("display" => "inlineBlock", "width" => "100%",
                    "marginLeft" => "auto", "fontWeight" => "bold",
                    "marginRight" => "auto", "marginTop" => "20px")),
                    #! Output: Interactive Graph SL2
                    cyto_cytoscape(id = "graphTab",
                    style = Dict("width" => "100%", "height" => "780px"),
                    layout = Dict("name" => "preset",),
                    autoRefreshLayout = false,
                    stylesheet = [
                        Dict("selector" => "node",
                        "style" => Dict("label" => "data(label)",
                        "textHalign" => "center", "textValign" => "center"))
                        ],
                    elements = graphElements)
                end
            end,
            #! Output: Graph Element Info
            html_div(className = "row") do 
                html_pre(id = "selectedElement",
                style = Dict("border" => "thin lightgrey solid", "width" => "100%",
                "marginTop" => "15px", "overflowX" => "scroll", "display" => "inlineBlock"))
            end
        )
    #! Tab 2
    elseif value == "Tab2"
        return(
            html_div() do
                dcc_markdown("""
                    Under construction.
                    """,
                    style = Dict("textAlign" => "justify", "fontWeight" => "bold", "fontSize" => "18px",
                    "paddingLeft" => "5px", "paddingRight" => "5px")),
                html_br()
            end
        )
    else
        return(html_div(html_h3("Error: Couldn't generate the tabs")))
    end
end

########################################################################################################################
###                                                Callback: Slide 1                                                 ###
########################################################################################################################
#! Callback: Graph Element Info
callback!(app,
Output("selectedElement", "children"),
[Input("graphTab", "selectedNodeData"),
Input("graphTab", "selectedEdgeData")]) do info_vtx, info_edg
    return([JSON.json(info_vtx), JSON.json(info_edg)])
end

#! Callback: Interactive Graph
callback!(app,
Output("graphTab", "elements"),
[Input("addVtx", "n_clicks"),
Input("removeVtx", "n_clicks"),
Input("addEdg", "n_clicks"),
Input("removeEdg", "n_clicks")],
[State("graphTab", "elements"),
State("graphTab", "selectedNodeData"),
State("graphTab", "selectedEdgeData")]) do mkvtx, rmvtx, mkedg, rmedg, elements, info_vtx, info_edg
    ctx = callback_context().triggered
    if isassigned(ctx, 1)
        #! Graph Manipulation: Add Vertex
        if ctx[1][:prop_id] == "addVtx.n_clicks"
            num_id = [parse(Int, lstrip(x[:data][:id], 'v')) for x ∈ elements if occursin("v", x[:data][:id])]
            n = minimum(setdiff(1:(maximum(num_id) + 1), num_id))            
            push!(elements, Dict("data" => Dict("id" => "v$(n)",
            "label" => "$(n)"), "position" => Dict("x" => 50, "y" => 50)))
            return(elements)
        end
        if !isnothing(info_vtx)
            #! Graph Manipulation: Remove Vertex
            if ctx[1][:prop_id] == "removeVtx.n_clicks"
                if length(info_vtx) > 0
                    id_vtx = [vtx[:id] for vtx ∈ info_vtx]
                    rlt_edg = [element[:data][:id] for element ∈ elements if (occursin('e', element[:data][:id]) && (element[:data][:source] ∈ id_vtx || element[:data][:target] ∈ id_vtx))]
                    return(filter(x -> x[:data][:id] ∉ vcat(id_vtx, rlt_edg), elements))
                else
                    println("At least one vertex must be selected in order to remove the element!")
                    return(elements)
                end
            end    
            #! Graph Manipulation: Add Edge    
            if ctx[1][:prop_id] == "addEdg.n_clicks"
                if length(info_vtx) == 2
                    id_vtx = sort([vtx[:label] for vtx ∈ info_vtx])
                    newedg = "e"*join(id_vtx)
                    if length(filter(x -> x[:data][:id] == newedg, elements)) == 0
                        push!(elements, Dict("data" => Dict("id" => "$(newedg)",
                        "source" => "v$(id_vtx[1])",
                        "target" => "v$(id_vtx[2])"),))
                        return(elements)
                    else
                        println("The selected vertices cannot be neighbours in order to add an edge!")
                        return(elements)
                    end
                else
                    println("Two vertices must be selected in order to add an edge!")
                    return(elements)
                end
            end
        end
        if !isnothing(info_edg)
            #! Graph Manipulation: Remove Edge
            if ctx[1][:prop_id] == "removeEdg.n_clicks"
                if length(info_edg) ≥ 1
                    id_edg = [edg[:id] for edg ∈ info_edg]
                    return(filter(x -> x[:data][:id] ∉ id_edg, elements))
                else
                    println("At least one edge must be selected in order to remove the element!")
                    return(elements)
                end    
            end
        end
        return(elements)
    end
    return(elements)
end

#! Callback: Interactive DataTable
callback!(app,
Output("graphTabOutput", "children"),
[Input("refreshInfo", "n_clicks")],
[State("propertySelection", "value"),
State("graphTab", "elements")]) do refresh, property, elements
    ctx = callback_context().triggered
    if isassigned(ctx, 1) && ctx[1][:prop_id] == "refreshInfo.n_clicks"
        vertices = []
        edges = []
        for element ∈ elements
            if occursin("v", element[:data][:id])
                push!(vertices,
                parse(Int, lstrip(element[:data][:id], 'v')))
            else
                push!(edges,
                parse.(Int, lstrip.([element[:data][:source], element[:data][:target]], 'v')))
            end
        end
        sort!(vertices)
        vtxdict = Dict{Int64, Int64}(enumerate(vertices))
        #! Generating graph
        graph = SimpleGraph(length(vertices))
        for edge ∈ edges
        add_edge!(graph, reverselookup(vtxdict, edge[1]), reverselookup(vtxdict, edge[2]))
        end
        #! Graph Property: Adjacency Matrix
        if property == "selectAdjMatrix"
            aux = Matrix(adjacency_matrix(graph))
            return(
                dash_datatable(id = "datatableGraph",
                columns = [Dict("name" => string(vtxdict[i]), "id" => string(i)) for i ∈ 1:size(aux, 2)],
                data = [Dict(string(j) => aux[i,j] for j ∈ 1:size(aux, 2)) for i ∈ 1:size(aux, 1)],
                page_size = 20,
                sort_action = "native",
                style_table = Dict("height" => "auto",
                "width" => "auto", "overflowY" => "auto",
                "overflowX" => "auto"),
                style_cell = Dict("minWidth" => "50px", "fontSize" => "16px"),
                style_header = Dict("fontWeight" => "bold",
                "backgroundColor" => "rgb(230, 230, 230)"))
                )
        #! Graph Property: Laplacian Matrix
        elseif property == "selectLapMatrix"
            aux = Matrix(laplacian_matrix(graph))
            return(
                dash_datatable(id = "datatableGraph",
                columns = [Dict("name" => string(vtxdict[i]), "id" => string(i)) for i ∈ 1:size(aux, 2)],
                data = [Dict(string(j) => aux[i,j] for j ∈ 1:size(aux, 2)) for i ∈ 1:size(aux, 1)],
                page_size = 20,
                sort_action = "native",
                style_table = Dict("height" => "auto",
                "width" => "auto", "overflowY" => "auto",
                "overflowX" => "auto"),
                style_cell = Dict("minWidth" => "50px", "fontSize" => "16px"),
                style_header = Dict("fontWeight" => "bold",
                "backgroundColor" => "rgb(230, 230, 230)"))
                )
        #! Graph Property: Eigenvalues
        elseif property == "selectAlgCon"
            aux = round.(laplacian_spectrum(graph), digits = 4)
            return([
                dash_datatable(id = "datatableGraph",
                columns = [Dict("name" => string(vtxdict[i]), "id" => string(i)) for i ∈ 1:length(aux)],
                data = [Dict(string(i) => aux[i] for i ∈ 1:length(aux))],
                page_size = 20,
                sort_action = "native",
                style_table = Dict("height" => "auto",
                "width" => "auto", "overflowY" => "auto",
                "overflowX" => "auto"),
                style_cell = Dict("minWidth" => "50px", "fontSize" => "16px"),
                style_header = Dict("fontWeight" => "bold",
                "backgroundColor" => "rgb(230, 230, 230)")),
                html_br(),
                html_br(),
                html_b("Laplacian Eigenvalues:",
                style = Dict("color" => "Tomato")),
                dcc_markdown("""
                The second smallest eigenvalue is the *Algebraic Connectivity* of the graph.
                """,
                style = Dict("textAlign" => "justify"))
            ])
        #! Graph Property: Fiedler's Vector
        elseif property == "selectFiedler"
            aux = eigen(Symmetric(Matrix(laplacian_matrix(graph))), 2:2)
            return([
                dash_datatable(id = "datatableGraph",
                columns = [Dict("name" => string(vtxdict[i]), "id" => string(i)) for i ∈ 1:length(aux.vectors)],
                data = [Dict(string(i) => round(aux.vectors[i], digits = 4) for i ∈ 1:length(aux.vectors))],
                page_size = 20,
                sort_action = "native",
                style_table = Dict("height" => "auto",
                "width" => "auto", "overflowY" => "auto",
                "overflowX" => "auto"),
                style_cell = Dict("minWidth" => "50px", "fontSize" => "16px"),
                style_header = Dict("fontWeight" => "bold",
                "backgroundColor" => "rgb(230, 230, 230)")),
                html_br(),
                html_br(),
                html_b("Fidler's Vector:",
                style = Dict("color" => "Tomato")),
                dcc_markdown("""
                The eigenvector associated with the second smallest eigenvalue is the *Fiedler's Vector* of the graph.
                """,
                style = Dict("textAlign" => "justify"))
            ])
        #! Graph Property: Reliability
        elseif property == "selectReliability"
            return([
                html_b("Reliability:",
                style = Dict("color" => "Tomato")),
                dcc_markdown("""
                The *Node Reliability* is given by the following function:.
                """,
                style = Dict("textAlign" => "justify")),
                html_img(src = "https://i.imgur.com/It7MGUC.png", width = "100%")
            ])
        else
            return("Select an option on the menu above.")
        end
    else
        return("Select an option on the menu above.")
    end
end

########################################################################################################################
###                                                     Server                                                       ###
########################################################################################################################
run_server(app, "0.0.0.0", 8080, debug = true)