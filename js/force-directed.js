import * as RDF from 'rdf'; // not rdflib
import * as d3 from 'd3';
import RDFViz from 'rdf-viz';

/*
import {
    forceLink, forceManyBody, forceCenter, forceCollide, forceSimulation
} from 'd3-force';
*/

//console.log(d3);

export default class ForceRDF extends RDFViz {
    constructor (graph, rdfParams = {}, d3Params = {}) {
        super(graph, rdfParams, d3Params);

        // these should be inputs
        const width  = d3Params.width  || 1000;
        const height = d3Params.height || 1000;

        // initialize the svg representation
        const svg = d3.create('svg')
              .attr('viewBox', [-width/2, -height/2, width, height]);
        // .attr("style", "width: 100%; height: 100%;");
        if (d3Params.width)  svg.attr('width',  d3Params.width);
        if (d3Params.height) svg.attr('height', d3Params.height);
        if (d3Params.preserveAspectRatio)
            svg.attr('preserveAspectRatio', d3Params.preserveAspectRatio);

        // this may be stupid
        this.svg = svg.node();
        this.svg.forceGraph = this;

        this.svg.addEventListener('graph', e => {
            const {
                subject: s, predicate: p, object: o, selected: t } = e.detail;
            const n = e.target;
            const g = (n.ownerSVGElement || n).forceGraph;

            // invert the inverses
            const i = Object.entries(g.inverses).reduce((h, [k, v]) => {
                h[g.abbreviate(k)] = g.abbreviate(v);
                return h;
            }, {});

            const me = window.location.href;
            //console.log(o);

            // edges
            let sel =
                `g.edge line[about~="${s}"][rel~="${p}"][resource~="${o}"]`;
            if (i[p]) sel +=
                `, g.edge line[about~="${o}"][rel~="${i[p]}"][resource~="${s}"]`;
            const m = n.querySelectorAll(sel);
            Array.from(m).forEach(
                c => c.classList[t ? 'add' : 'remove']('subject'));

            // nodes
            const x = n.querySelectorAll(`g.node a[about="${o}"]`);
            Array.from(x).forEach(
                c => c.classList[t ? 'add' : 'remove']('subject'));
        });
    }

    init () {
        // select the svg into the d3 wrapper
        const svg = d3.select(this.svg);

        // make these shorter to type lol
        const graph      = this.graph,
              a          = this.a,
              ns         = this.ns,
              validTypes = this.validTypes,
              labels     = this.labels,
              inverses   = this.inverses,
              symmetric  = this.symmetric;

        // first we get all the nodes of valid types
        const nmap  = {};
        const nodes = this.nodes = [];

        graph.match(null, a).forEach(stmt => {
            if (validTypes.some(t => t.equals(stmt.object))) {
                // get the label
                let label = stmt.subject.value;
                const lp = [ns['dct']('title'), ns['rdfs']('label')];
                if (labels[stmt.object.value])
                    lp.unshift(labels[stmt.object.value]);
                for (let i = 0; i < lp.length; i++) {
                    let x = graph.match(stmt.subject, lp[i]).filter(
                        s => s.object.termType == 'Literal');
                    if (x.length > 0) {
                        label = x[0].object.value;
                        break;
                    }
                }

                const s = this.rewriteUUID(stmt.subject);

                // get the in+outdegree
                const degree = graph.match(stmt.subject).filter(
                    s => s.object.termType == 'NamedNode').length +
                      graph.match(null, null, stmt.subject).filter(
                          s => s.subject.termType == 'NamedNode').length - 1;

                // add this mess to the list
                nodes.push(nmap[stmt.subject.value] = {
                    id:      s.value, // for d3
                    title:   label, // for d3
                    subject: stmt.subject,
                    type:    stmt.object,
                    degree:  degree,
                });
            }
        });

        // then we get all the links between the nodes, turning them
        // around if we need to
        const lmap  = {};
        const links = this.links = [];
        nodes.forEach(rec => {
            // we already know these are here
            graph.match(rec.subject).forEach(stmt => {
                // only look at the edges containing nodes we already have
                if (!nmap[stmt.object.value]) return;
                let s = stmt.subject, p = stmt.predicate, o = stmt.object;
                if (inverses[p.value]) {
                    s = stmt.object;
                    p = inverses[p.value];
                    o = stmt.subject;
                }

                let src = this.rewriteUUID(s);
                let tgt = this.rewriteUUID(o);

                // console.log(src, tgt);

                // this ensures we have no duplicate edges
                if (!lmap[p.value]) lmap[p.value] = {};
                if (!lmap[p.value][s.value]) lmap[p.value][s.value] = {};
                if (lmap[p.value][s.value][o.value]) return;

                links.push(lmap[p.value][s.value][o.value] = {
                    source: src.value, // for d3
                    target: tgt.value, // for d3
                    subject: s,
                    predicate: p,
                    object: o
                });
            });
        });

        // initialize the simulation

        const fn = d3.forceManyBody();
        const fl = d3.forceLink(links).id(({ index: i }) => nodes[i].id);
        const fc = d3.forceCollide(20);

        const maxDegree = nodes.reduce(
            (weight, node) => node.degree > weight ? node.degree : weight, 0);

        // set repulsion strength
        fn.strength(d => -d.degree / maxDegree);
        fn.distanceMin(10);
        fn.distanceMax(50);

        const simulation = this.simulation = d3.forceSimulation(nodes)
              .force('link', fl).force('charge', fn)
              .force('center', d3.forceCenter(0.25)).force('collide', fc);

        function ticked() {
            function ugh (end, coord) {
                return function (d) {
                    let dx = d.target.x - d.source.x;
                    let dy = d.target.y - d.source.y;
                    let theta = Math.atan2(dy, dx);

                    // the value
                    let out = d[end][coord];

                    // we have to shorten the line by a certain amount so
                    // the point of the arrowhead touches the edge of the node
                    if (end == 'target') {
                        const t = d.target;
                        // no arrowhead for symmetric properties
                        if (symmetric.some(s => s.equals(t.predicate)))
                            return out;

                        // degree divided in half for radius plus ten
                        // for the arrow
                        let mx = Math.cos(theta) * ((t.degree + 10) / 2 + 10);
                        let my = Math.sin(theta) * ((t.degree + 10) / 2 + 10);

                        // console.log(mx, my);

                        // now we shorten the line
                        out -= coord == 'y' ? my : mx;
                    }

                    return out;
                };
            }

            edge.attr("x1", ugh('source', 'x')).attr("y1", ugh('source', 'y'))
                .attr("x2", ugh('target', 'x')).attr("y2", ugh('target', 'y'));

            node.attr('transform', d => `translate(${d.x},${d.y})`);

            //node.attr("cx", d => d.x).attr("cy", d => d.y);
        }

        function drag (simulation) {
            function dragStarted (event) {
                // XXX magic number 0.3
                if (!event.active) simulation.alphaTarget(0.3).restart();

                event.subject.fx = event.x;
                event.subject.fy = event.y;
            }

            function dragged (event) {
                event.subject.fx = event.x;
                event.subject.fy = event.y;
            }

            function dragStopped (event) {
                event.subject.fx = null;
                event.subject.fy = null;
            }

            return d3.drag()
                .on('start', dragStarted)
                .on('drag', dragged)
                .on('end', dragStopped);
        }

        const edge = svg.append('g')
              .attr('class', 'force edge')
              .selectAll('line')
              .data(links)
              .join('line')
              .attr('about',    e => e.source.id)
              .attr('rel',      e => this.abbreviate(e.predicate))
              .attr('resource', e => e.target.id)
              .attr('class',    e => [e.source, e.target].some(
                  x => x.id == window.location.href) ? 'subject' : null)
        // .attr('marker-end',
        //       e => `url(#${this.abbreviate(e.predicate).replace(':', '.')})`)
              .attr('stroke-width', 1);

        const nodeHover = state => {
            return e => {
                const a = e.currentTarget;
                const svg = a.ownerSVGElement;
                const s = window.location.href;
                const o = a.href.baseVal;
                Array.from(svg.querySelectorAll(
                    `g.edge line[about="${o}"], g.edge line[resource="${o}"]`))
                    .forEach(edge => {
                        const es = edge.getAttribute('about');
                        const eo = edge.getAttribute('resource');
                        if (state) edge.classList.add('subject');
                        else if (s != o && s != es && s != eo) {
                            edge.classList.remove('subject');
                        }
                    });
            };
        };

        const defs = svg.append('defs');

        // let's make a bunch of markers then i guess
        Object.keys(lmap).forEach(predicate => {
            const about = this.abbreviate(predicate);
            const id = about.replace(':', '.'); // make this a legal id
            ['', '.subject'].forEach(x => {
                defs.append('marker').attr('id', id + x)
                    .attr('markerWidth', 10).attr('markerHeight', 7)
                    .attr('refX', 0).attr('refY', 3.5).attr('orient', 'auto')
                    .append('polygon').attr('points', '0,0 10,3.5 0,7')
                    .attr('class', () => x ? 'subject' : null)
                    .attr('about', about);
            });
        });

        svg.append('defs').append('marker')
            .attr('id', 'arrowhead').attr('markerWidth', 10).attr('markerHeight', 7)
            .attr('refX', 0).attr('refY', 3.5).attr('orient', 'auto')
            .append('polygon').attr('points', '0,0 10,3.5 0,7');

        const node = svg.append('g')
              .attr('class', 'force node')
              .selectAll('a')
              .data(nodes)
              .join('a')
              .attr('class', n => n.id == window.location.href ? 'subject' : null)
              .attr('about', n => n.id) // redundant but xlink:href can't select
              .attr('xlink:href', n => n.id)
              .attr('typeof', n => this.abbreviate(n.type))
              .on('mouseover', nodeHover(true))
              .on('mouseout', nodeHover(false))
              .call(drag(simulation));

        node.append('circle').attr('class', 'target')
            .attr('r',      n => (n.degree + 10));
        node.append('circle')
            .attr('r',     n => (n.degree + 10) / 2)
        //          .attr('r',      n => (Math.sqrt(n.degree) + 10) / 2)
            .append('title').text(n => n.title);

        // pretty sure this markup is wrong

        // move this down here because it misbehaves otherwise
        simulation.on('tick', ticked);
    }
}

// add uniq
Array.prototype.uniq = Array.prototype.uniq || function () {
    let cache = new Set();
    return this.reduce((prev, cur) => {
        if (!cache.has(cur)) prev.push(cur);
        cache.add(cur);
        return prev;
    }, []);
};
