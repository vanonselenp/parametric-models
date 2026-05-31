// ============================================================
// Bolt Action Pin Marker Dial - Two-Part Snap-Fit
// ============================================================
// Two separate parts printed flat on the bed, snap together
// post-print with a single press-fit action.
//
// Base piece: flat disc with embossed numbers + central cylinder
//             pointing up, with a snap lip near the top.
// Top piece:  flat disc with arc window cutout, central through-hole
//             that snaps past the lip and is captured beneath it.
//
// Designed for AMS multi-material printing:
//   - Body in faction colour (e.g. red, grey, khaki)
//   - Numbers in white via filament change at top of base disc layer
//   - Faction art crayon-filled post-print
//
// MakerWorld parametric SCAD compatible.
// ============================================================

/* [Dial Geometry] */
// Outer diameter of the dial (mm)
outer_diameter = 38; // [28:0.5:50]
// Thickness of the bottom (base) disc carrying the numbers (mm)
base_thickness = 2.5; // [2:0.1:4]
// Thickness of the top (rotating) disc carrying the window (mm)
top_thickness = 2.3; // [2:0.1:4]
// Z-axis gap between disc faces when assembled (mm)
z_gap = 0.4; // [0.2:0.05:0.8]
// Radial clearance between cylinder shaft and top piece hole (mm, per side)
radial_gap = 0.5; // [0.3:0.05:1.0]

/* [Order Die Holder] */
// Edge length of the cubic order die (mm) - standard d6 is 16mm
die_size = 16; // [10:0.5:20]
// Total clearance around the die in the square pocket (mm)
die_clearance = 0.5; // [0.3:0.1:1.0]
// Wall thickness at the square pocket corners (mm) - the thinnest point
cylinder_corner_wall = 1.2; // [0.8:0.1:2.5]
// Cylinder height above the snap lip - extra grip on the die (mm)
upper_shaft_height = 3.0; // [0:0.5:10]

/* [Snap Lip] */
// Lip interference - how much lip radius exceeds the hole radius (mm)
// Higher = more secure capture, harder to press together
lip_interference = 0.3; // [0.15:0.05:0.6]
// Lip height (mm) - the cone tapers from full lip OD down to shaft OD
lip_height = 0.6; // [0.4:0.1:1.5]

/* [Number Ring] */
// Number of positions around the dial (Bolt Action uses 12 for 0-11)
number_count = 12; // [6:1:16]
// Embossed number height above base surface (mm)
number_emboss_height = 0.6; // [0.3:0.1:1.2]
// Font size for the numbers (mm)
number_font_size = 3.5; // [2:0.1:6]
// Font for the numbers
number_font = "Liberation Sans:style=Bold";
// Radial position of number centres (mm from dial centre)
number_radius = 16.0; // [9:0.1:22]

/* [Arc Window] */
// Angular width of the visible window (degrees)
window_arc_degrees = 30; // [20:1:60]
// Inner radius of the window cutout (mm)
window_inner_radius = 14.0; // [8:0.1:20]
// Outer radius of the window cutout (mm) - keep slightly inside dial edge
window_outer_radius = 18.0; // [10:0.1:24]

/* [Faction Symbol] */
// Which faction symbol to emboss on the top piece
faction = "soviet"; // [soviet, german, british, none]
// Overall size (diameter) of the faction symbol (mm)
faction_symbol_size = 5.0; // [3:0.1:9]
// Emboss height of the faction symbol (mm)
faction_emboss_height = 0.6; // [0.3:0.1:1.2]
// Radial offset from centre to symbol centre (mm)
faction_symbol_offset = 12.0; // [0:0.1:22]

/* [Render Options] */
// What to render
render_mode = "print"; // [print, assembled, exploded, base_only, top_only]
// Spacing between parts in print layout (mm)
print_gap = 4; // [1:0.5:15]

/* [Hidden] */
$fn = $preview ? 48 : 96;
eps = 0.01;

// ============================================================
// DERIVED DIMENSIONS
// ============================================================

dial_radius     = outer_diameter / 2;
die_pocket_size = die_size + die_clearance;
die_pocket_diag = die_pocket_size * sqrt(2);

shaft_d         = die_pocket_diag + 2 * cylinder_corner_wall;
hole_d          = shaft_d + 2 * radial_gap;
lip_d           = hole_d + 2 * lip_interference;

// Z stack of the assembled dial (bottom-up)
z_base_top      = base_thickness;
z_top_bottom    = z_base_top + z_gap;
z_top_top       = z_top_bottom + top_thickness;
z_lip_bottom    = z_top_top + z_gap;
z_lip_top       = z_lip_bottom + lip_height;
z_cylinder_top  = z_lip_top + upper_shaft_height;

// ============================================================
// UTILITY MODULES
// ============================================================

module sector_2d(r, a) {
    steps = max(8, ceil(a / 4));
    pts = concat(
        [[0, 0]],
        [for (i = [0 : steps])
            [r * cos(i * a / steps), r * sin(i * a / steps)]]
    );
    polygon(pts);
}

module ring_2d(r_outer, r_inner) {
    difference() {
        circle(r = r_outer);
        circle(r = r_inner);
    }
}

// ============================================================
// FACTION SYMBOLS (2D)
// ============================================================

module soviet_star_2d(size) {
    r_o = size / 2;
    r_i = r_o * 0.42;
    pts = [for (i = [0 : 9])
        let (
            ang = 90 + i * 36,
            r = (i % 2 == 0) ? r_o : r_i
        )
        [r * cos(ang), r * sin(ang)]
    ];
    polygon(pts);
}

module german_balkenkreuz_2d(size) {
    width = size * 0.32;
    union() {
        square([size, width], center = true);
        square([width, size], center = true);
    }
}

module british_parachute_2d(size) {
    canopy_r = size / 2;
    body_w   = size * 0.18;
    body_h   = size * 0.22;
    gap      = size * 0.06;
    union() {
        intersection() {
            circle(r = canopy_r);
            translate([-canopy_r, 0])
                square([canopy_r * 2, canopy_r]);
        }
        for (x = [-canopy_r * 0.6, canopy_r * 0.6])
            translate([x / 2, -gap / 2])
                rotate([0, 0, atan2(-gap, -x)])
                    square([sqrt(x * x + gap * gap), size * 0.04]);
        translate([0, -gap - body_h / 2])
            square([body_w, body_h], center = true);
    }
}

module faction_symbol_2d() {
    if (faction == "soviet")        soviet_star_2d(faction_symbol_size);
    else if (faction == "german")   german_balkenkreuz_2d(faction_symbol_size);
    else if (faction == "british")  british_parachute_2d(faction_symbol_size);
}

// ============================================================
// NUMBER RING (clockwise from 12 o'clock)
// ============================================================

module embossed_numbers() {
    for (i = [0 : number_count - 1]) {
        ang = 90 - i * (360 / number_count);
        rotate([0, 0, ang])
            translate([number_radius, 0, 0])
                rotate([0, 0, ang - 90])
                    linear_extrude(height = number_emboss_height)
                        text(str(i),
                             size = number_font_size,
                             font = number_font,
                             halign = "center",
                             valign = "center");
    }
}

module arc_window_cutter() {
    half = window_arc_degrees / 2;
    rotate([0, 0, -90 - half])
        linear_extrude(height = top_thickness + 2 * eps)
            intersection() {
                ring_2d(window_outer_radius, window_inner_radius);
                sector_2d(window_outer_radius + 1, window_arc_degrees);
            }
}

// ============================================================
// BASE PIECE
// Flat disc + numbers + central cylinder with snap lip
// Prints flat on the bed, cylinder pointing up
// ============================================================

module base_piece() {
    // Disc with embossed numbers
    union() {
        cylinder(d = outer_diameter, h = base_thickness);
        translate([0, 0, base_thickness - eps])
            difference() {
                embossed_numbers();
                translate([0, 0, -eps])
                    cylinder(d = shaft_d, h = number_emboss_height + 2 * eps);
            }
    }

    // Central cylinder with snap lip, single difference()
    // Outer profile from bottom to top:
    //   shaft (shaft_d) → lip frustum (lip_d at bottom, shaft_d at top) → upper shaft
    // Square pocket subtracted through the entire cylinder
    difference() {
        union() {
            // Lower shaft - top piece rotates here when assembled
            translate([0, 0, z_base_top])
                cylinder(d = shaft_d, h = z_lip_bottom - z_base_top);
            // Snap lip: frustum, wider at bottom (capture shoulder) tapering up
            translate([0, 0, z_lip_bottom])
                cylinder(d1 = lip_d, d2 = shaft_d, h = lip_height);
            // Upper shaft for additional die grip
            if (upper_shaft_height > 0)
                translate([0, 0, z_lip_top])
                    cylinder(d = shaft_d, h = upper_shaft_height);
        }
        // Square die pocket through entire cylinder
        translate([-die_pocket_size / 2, -die_pocket_size / 2, z_base_top - eps])
            cube([die_pocket_size,
                  die_pocket_size,
                  z_cylinder_top - z_base_top + 2 * eps]);
    }
}

// ============================================================
// TOP PIECE
// Flat disc with central hole, arc window, embossed faction art
// Prints flat on the bed
// ============================================================

module top_piece() {
    difference() {
        // Disc body
        cylinder(d = outer_diameter, h = top_thickness);
        // Central through-hole sized for snap-fit over the cylinder
        translate([0, 0, -eps])
            cylinder(d = hole_d, h = top_thickness + 2 * eps);
        // Arc window
        translate([0, 0, -eps])
            arc_window_cutter();
    }

    // Faction symbol embossed on top, opposite the window (12 o'clock)
    if (faction != "none") {
        sym_pos = faction_symbol_offset > 0 ? faction_symbol_offset : 0;
        translate([0, sym_pos, top_thickness - eps])
            linear_extrude(height = faction_emboss_height + eps)
                faction_symbol_2d();
    }
}

// ============================================================
// RENDER MODES
// ============================================================

module assembled() {
    base_piece();
    translate([0, 0, z_top_bottom])
        top_piece();
}

module exploded() {
    base_piece();
    translate([0, 0, z_cylinder_top + 6])
        top_piece();
}

module print_layout() {
    // Both parts flat on the bed, side by side, ready to slice
    translate([-(outer_diameter / 2 + print_gap / 2), 0, 0])
        base_piece();
    translate([+(outer_diameter / 2 + print_gap / 2), 0, 0])
        top_piece();
}

if (render_mode == "print")           print_layout();
else if (render_mode == "assembled")  assembled();
else if (render_mode == "exploded")   exploded();
else if (render_mode == "base_only")  base_piece();
else if (render_mode == "top_only")   top_piece();
