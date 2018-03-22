function [out pts_out] = ham_latch(h_latch)
% Function to create a latch
% p0 = coordinate of middle of rotor
% r  = [inner radius, outer radius]
% n = number of points in the circles of the rotor
% layer = GDS layer to place circle into


if ~isfield(h_latch,'manual_theta')
    h_latch.manual_theta = 0;
end

if ~isfield(h_latch,'flip_spring')
    h_latch.flip_spring = 0;
end





if ~isfield(h_latch,'blength')
    h_latch.blength = 22;
end

if ~isfield(h_latch,'compact_ang1')
    h_latch.compact_ang1 = 197;
end

if ~isfield(h_latch,'vapr_relay')
    h_latch.vapr_relay = 0;
end

if ~isfield(h_latch,'ss')
    h_latch.ss.n = 6;
    h_latch.ss.dpp = 70;                          %was 70 in the designs that worked
    h_latch.ss.dist_from_rotor = 200;
end

if ~isfield(h_latch.ss,'spring_w')
    h_latch.ss.spring_w = 4;
end


if ~isfield(h_latch,'h_relay')
    h_latch.h_relay.contact_type = 1;
    h_latch.h_relay.contact_head_type = 1;
    h_latch.h_relay.springw = 5;
    h_latch.h_relay.dc_offset = 3;
end





if ~isfield(h_latch,'zif')
    h_latch.zif = 0;
end



h_etch.noetch = h_latch.noetch;

h_latch.theta = pi/180*h_latch.theta;
latch_actuation_angle =h_latch.actuation_angle*pi/180;

if h_latch.compact_latch
    if h_latch.orientation==1
        latch_arm_initial_angle = -pi/2 - (h_latch.theta - 2*pi/9) + h_latch.manual_theta;
        latch_arm_initial_angle_2 = pi/180*h_latch.theta_arm;
    else
        latch_arm_initial_angle = -pi/2 + (h_latch.theta - 5.5*pi/9) + h_latch.manual_theta;
        latch_arm_initial_angle_2 = pi/180*h_latch.theta_arm;
    end
else
    %Standard non-compact design
    latch_arm_initial_angle = pi/180*h_latch.theta_arm;
    latch_arm_initial_angle_2 = pi/180*h_latch.theta_arm;
end

if ~isfield(h_latch,'n')
    h_latch.n = 100;
end

if ~isfield(h_latch,'gim')
    h_latch.gim = 0;
end


if ~isfield(h_latch,'downsample')
    h_latch.downsample = 2;
end

if ~isfield(h_latch,'ss_meander_spline')
    h_latch.ss_meander_spline = 0;
end


if ~isfield(h_latch,'compact_latch')
    h_latch.compact_latch = 0;
end



%If the latch should be closed...rotate all things.
if h_latch.closed ==1
    h_latch.theta_arm = h_latch.theta_arm - h_latch.orientation*latch_actuation_angle*180/pi;
    %h_latch.theta_arm = h_latch.theta_arm -  h_latch.theta*180/pi;
    h_latch.theta = h_latch.theta - h_latch.orientation*latch_actuation_angle;
end

%Create rotor
points = zeros(2*(h_latch.n+1),2);
for j=1:2
    if j==2
        mult = -1;
    else
        mult = 1;
    end
    for i=1:h_latch.n+1
        %Adding 50nm to each radius to fix rounding errors
        points(i + (j-1)*(h_latch.n+1),1) = h_latch.p0(1) + (h_latch.r(j)+.05)*cos(mult*i*2*pi/h_latch.n);
        points(i + (j-1)*(h_latch.n+1),2) = h_latch.p0(2) + (h_latch.r(j)+.05)*sin(mult*i*2*pi/h_latch.n);
    end
end
rotor_points = [points(end,:);points];
outer_rotor_ring = rotor_points(h_latch.n+1:end,:);

be = gds_element('boundary', 'xy',rotor_points,'layer',h_latch.layer);
str_name = sprintf('Rotor_[%d,%d],[%d]',round(h_latch.p0(1)),round(h_latch.p0(2)),round(h_latch.r(1)));
rot = gds_structure(str_name,be);

%Make etch holes in rotor
h_etch.regions = cell(1,1);
h_etch.r = 2;
h_etch.undercut = 6;
section.p0 = [h_latch.p0(1), h_latch.p0(2)];
section.type = 'annulus';
section.r = h_latch.r;
h_etch.regions{1,1} = section;
rotor_holes = etch_hole(h_etch);

%Creates Pin
h_cir.x = h_latch.p0(1);
h_cir.y = h_latch.p0(2);
h_cir.r = h_latch.r(1)-h_latch.pin_gap;
h_cir.layer = 6;
h_cir.n = 100;
pin_head = circle(h_cir);


%Add birds beak
h_latch.phi = h_latch.theta +  h_latch.orientation*pi/4; %flipped sign
h_latch.phi2 = h_latch.phi +  h_latch.orientation*pi/20; %flipped sign
h_latch.phi3 = h_latch.phi2 +  h_latch.orientation*pi/20; %flipped sign





%Find various points that will make up the bird's beak
p1 = h_latch.p0 + h_latch.r(2)*[-cos(h_latch.theta) sin(h_latch.theta)];
p2 = h_latch.p0 + (h_latch.r(2)+h_latch.blength)*[-cos(h_latch.theta) sin(h_latch.theta) ];
p3 = h_latch.p0 + (h_latch.r(2)+2*h_latch.blength)*[-cos(h_latch.theta) sin(h_latch.theta) ];
p4 = h_latch.p0 + h_latch.r(2)*[-cos(h_latch.phi) sin(h_latch.phi) ];
p5 = midpt(p3,p4,.6);
p6 = h_latch.p0 + h_latch.r(2)*[-cos(h_latch.phi2) sin(h_latch.phi2) ];
p7 = h_latch.p0 + h_latch.r(2)*[-cos(h_latch.phi3) sin(h_latch.phi3) ];

init_points = [p7' p6' p4' p5' p2'];

interm_pts = fnplt(cscvn(init_points));

final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),h_latch.downsample) interm_pts(1,end);
    interm_pts(2,1) downsample(interm_pts(2,2:end-1),h_latch.downsample) interm_pts(2,end)];

points = [p1;final_pts'];
ca = gds_element('boundary', 'xy',points,'layer',h_latch.layer);


str_name = sprintf('Birds_Beak_[%d,%d]',round(p2(1)),round(p2(2)));
bbeak = gds_structure(str_name,ca);


%Puts etch holes in the birds beak
h_etch.regions = cell(1,1);
h_etch.r = 2;
h_etch.undercut = 6;
section.arc = final_pts';
%section.arc = final_pts';
section.p0 = h_latch.p0;
section.theta2 = h_latch.theta;
section.r = h_latch.r;
section.bbfillet = h_latch.bbeak_fillet_length; %Length of birds beak fillet
section.type = 'arc';
section.orientation = h_latch.orientation;
h_etch.regions{1,1} = section;
beak_holes = etch_hole(h_etch);

%Add fillet to beak
h_fillet.d = .5;
h_fillet.layer = 6;
h_fillet.p0 = p1;

beak_fillet_theta = 2*section.bbfillet/h_latch.r(2);
theta_0 = atan2(h_fillet.p0(2)-h_latch.p0(2),h_fillet.p0(1)-h_latch.p0(1));


h_fillet.p1 = h_latch.p0 + [h_latch.r(2)*cos(theta_0+h_latch.orientation*beak_fillet_theta) h_latch.r(2)*sin(theta_0+h_latch.orientation*beak_fillet_theta)];

snap_angle = .0001;
h_fillet.p2 = h_latch.p0 + (h_latch.r(2)+section.bbfillet)*[-cos(h_latch.theta+h_latch.orientation*snap_angle) sin(h_latch.theta+h_latch.orientation*snap_angle)];
beak_fillet = fillet(h_fillet);


%Get points for next latch
um_from_bbeak_to_tab = 4;               % This is the extra space from the end of one lever arm to the next rotor
h_arm.x = h_latch.p0(1) - h_latch.armw/2.0;
%h_arm.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml - h_latch.r(2) - um_from_bbeak_to_tab;
h_arm.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml - h_latch.r(2) - um_from_bbeak_to_tab;
h_arm.w = h_latch.armw;
h_arm.l = h_latch.arml;
h_arm.layer = 6;
h_arm.rp = 1;



%just added
if h_latch.closed == 0
    h_arm.theta = pi/180*(-h_latch.theta_arm-90);
    h_arm.p0 = h_latch.p0;
    latch_arm_pts = rect(h_arm);
    h_arm.rp = 0;
else
    h_latch.theta_arm = h_latch.theta_arm + h_latch.orientation*latch_actuation_angle*180/pi;
    h_arm.theta = pi/180*(-h_latch.theta_arm-90);
    h_arm.p0 = h_latch.p0;
    latch_arm_pts = rect(h_arm);
    h_arm.rp = 0;
    h_latch.theta_arm = h_latch.theta_arm - h_latch.orientation*latch_actuation_angle*180/pi;
end

if h_latch.orientation ==1
    latch_arm_pt = latch_arm_pts(1,:);
else
    latch_arm_pt = latch_arm_pts(2,:);
end


%Add arm to latch
h_arm.x = h_latch.p0(1) - h_latch.armw/2.0;
h_arm.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml;
h_arm.w = h_latch.armw;
h_arm.l = h_latch.arml;
h_arm.layer = 6;

h_arm.theta = pi/180*(-h_latch.theta_arm-90);
h_arm.p0 = h_latch.p0;
latch_arm = rect(h_arm);

%Dummy fill for arm
%Short and fat
extra = 110;
h_armdf.x = h_latch.p0(1) - h_latch.orientation*h_latch.armw/2.0 - h_latch.orientation*extra;
h_armdf.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml - extra;
h_armdf.w = h_latch.orientation*(h_latch.armw + (h_latch.arml+2*h_latch.r(2))*sin(latch_actuation_angle));
h_armdf.l = h_latch.arml*(2/3);
h_armdf.layer = 8;

h_armdf.theta = pi/180*(-h_latch.theta_arm-90);
h_armdf.p0 = h_latch.p0;
latch_arm_df = rect(h_armdf);

%Dummy fill for arm (tall and skinnier)
h_armdf.x = h_latch.p0(1) - h_latch.orientation*h_latch.armw/2.0 - h_latch.orientation*extra;
h_armdf.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml - extra;
h_armdf.w = .7*h_latch.orientation*(h_latch.armw + (h_latch.arml+2*h_latch.r(2))*sin(latch_actuation_angle));
h_armdf.l = h_latch.arml + 2*extra;
h_armdf.layer = 8;

h_armdf.theta = pi/180*(-h_latch.theta_arm-90);
h_armdf.p0 = h_latch.p0;
latch_arm_df2 = rect(h_armdf);



if h_latch.orientation ==  1
    %Add Hammer head to the lever arm
    h_cir.x = h_latch.p0(1) - h_latch.armw/2.0;
    h_cir.y = h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml + h_latch.hhead_r + 20; %20 is offset from mechanical latch/bbeak
    h_cir.r = h_latch.hhead_r;
    h_cir.layer = 6;
    
    h_rot.theta = pi/180*(-h_latch.theta_arm-90);
    h_rot.p0 = h_latch.p0;
    h_rot.pts = [h_cir.x h_cir.y];
    
    pcent = rotate_pts(h_rot);
    h_cir.x = pcent(1);
    h_cir.y = pcent(2);
    %latch_hammer_head = circle(h_cir);
    
    %Add etch holes to hammer head on latch
    h_etch.regions = cell(1,1);
    h_etch.r = 2;
    h_etch.undercut = 6;
    h_etch.p0 = pcent;
    section.p0 = pcent;
    section.type = 'semicircle_l';
    section.r =  h_latch.hhead_r;
    h_etch.regions{1,1} = section;
    
    h_etch.rotation_point = pcent;
    h_etch.rotation_angle = h_latch.theta_arm + 90;
    %latch_ham_head_holes = etch_hole(h_etch);
    
    
    %If this is an inchworm-driven hammer, adds joint onto the end of the
    %lever arm.
    if h_latch.inchworm ==1
        
        arm_size = 35;
        h_joint = h_latch.h_joint;
        distance_from_edge = 150;
        
        %The first joint directly below the lever arm
        h_joint.p0 = [h_latch.p0(1) h_latch.p0(2)-sqrt(h_latch.r(2)^2-(h_latch.armw/2)^2)-h_latch.arml-distance_from_edge];
        
        %Find the point where the bottom joint of the lever arm rotates to
        %when closed
        h_rot.pts = h_joint.p0(1,:);
        %h_rot.theta =  h_latch.theta_arm*pi/180 - h_latch.orientation*latch_actuation_angle;
        h_rot.theta =  h_latch.orientation*latch_actuation_angle;
        h_rot.p0 = h_latch.p0;
        h_joint.p1_f = rotate_pts(h_rot);
        h_joint.p1_f_theta = (90-h_latch.init_angle)*pi/180;
        h_joint.p1_f_theta = (h_latch.init_angle)*pi/180;
        
        
        %Now calculate the second joint
        %Moves a certain distance from p1 for now
        p1_dist = 500;
        h_joint.p0_2 = h_joint.p1_f + p1_dist*[-cos(h_joint.p1_f_theta) -sin(h_joint.p1_f_theta)];
        h_joint.p2 = h_joint.p0(1,:) + [0 distance_from_edge+h_joint.gap];
        
        
        %First joint right below lever arm
        %Inner arm
        h_joint.p1 = midpt(h_joint.p0(1,:),h_joint.p0_2,.5);
        h_joint.inner_arm_theta = atan2d(h_joint.p1(2)-h_joint.p0(2),h_joint.p1(1)-h_joint.p0(1));  % Angle of the inner arm in degrees
        h_joint.inner_arm_l = sqrt((h_joint.p0(2)-h_joint.p1(2))^2+(h_joint.p0(1)-h_joint.p1(1))^2);
        h_joint.inner_arm_w = arm_size;
        
        %Outer Arm
        h_joint.outer_arm_theta = atan2d(h_joint.p2(2)-h_joint.p0(2),h_joint.p2(1)-h_joint.p0(1));  % Angle of the inner arm in degrees
        h_joint.outer_arm_l = sqrt((h_joint.p0(2)-h_joint.p2(2))^2+(h_joint.p0(1)-h_joint.p2(1))^2) - h_joint.r(1) - h_joint.gap + h_joint.overlap;
        h_joint.outer_arm_w = h_latch.armw;
        %h_joint.outer_arm_w = arm_size;
        g_joint_1 = joint(h_joint);
        
        %Second joint
        %Inner arm
        h_joint.p2 = midpt(h_joint.p0,h_joint.p0_2,.5);
        h_joint.p0 = h_joint.p0_2;
        h_joint.p1 = h_joint.p1_f;
        
        h_joint.inner_arm_theta = atan2d(h_joint.p1(2)-h_joint.p0(2),h_joint.p1(1)-h_joint.p0(1));  % Angle of the inner arm in degrees
        h_joint.inner_arm_l = sqrt((h_joint.p0(2)-h_joint.p1(2))^2+(h_joint.p0(1)-h_joint.p1(1))^2);
        h_joint.inner_arm_w = arm_size;
        
        %Outer Arm
        h_joint.outer_arm_theta = atan2d(h_joint.p2(2)-h_joint.p0(2),h_joint.p2(1)-h_joint.p0(1));  % Angle of the inner arm in degrees
        h_joint.outer_arm_l = sqrt((h_joint.p0(2)-h_joint.p2(2))^2+(h_joint.p0(1)-h_joint.p2(1))^2) - h_joint.r(1) - h_joint.gap + h_joint.overlap;
        
        h_joint.outer_arm_w = arm_size;
        g_joint_2 = joint(h_joint);
        
    end
    
end


%Add etch holes in arm
h_etch.regions = cell(1,1);
section.type = 'tcurve';
section.p0 = [h_arm.x h_arm.y];
section.tcurve = outer_rotor_ring;

h_etch.r = 2;
h_etch.undercut = 6;
h_etch.w = h_arm.w;
h_etch.regions{1,1} = section;
h_etch.rotation_angle = h_latch.theta_arm + 90;
h_etch.rotation_point = h_latch.p0;
arm_etch_holes = etch_hole(h_etch);

%Add fillets at the intersection of the rotor and lever arm
%Left and etch hole
snap = .01;
h_fillet.d = .6;
h_fillet.layer = 6;
h_fillet.p0 = [h_arm.x+snap h_arm.y+h_arm.l];

lever_fillet = 30; %Length of the fillet along the lever arm

lever_fillet_theta = atan2(h_arm.y+h_arm.l - h_latch.p0(2),h_arm.x - h_latch.p0(1)) - lever_fillet/h_latch.r(2);

h_fillet.p1 = h_fillet.p0 + [0 -lever_fillet];

h_fillet.p2 = h_latch.p0 + (h_latch.r(2)-.005)*[cos(lever_fillet_theta) sin(lever_fillet_theta)];

%Rotate P0,P1, and P2
h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
h_rot.p0 = h_latch.p0;
out=rotate_pts(h_rot);

h_fillet.p0 = out(1,:);
h_fillet.p1 = out(2,:);
h_fillet.p2 = out(3,:);

latch_fillet_l = fillet(h_fillet);

if h_latch.noetch == 0
    %Creates etch hole in fillet
    h_cir.x = h_fillet.p0(1);
    h_cir.y = h_fillet.p0(2);
    h_cir.r = 2;
    h_cir.layer = 2;
    h_cir.n = 25;
    l_fillet_etch = circle(h_cir);
end

%Right
h_fillet.d = .5;
h_fillet.layer = 6;
h_fillet.p0 = [h_arm.x+h_latch.armw-snap h_arm.y+h_arm.l];

lever_fillet_theta = atan2(h_arm.y+h_arm.l - h_latch.p0(2),h_arm.x+h_latch.armw - h_latch.p0(1)) + lever_fillet/h_latch.r(2);

h_fillet.p1 = h_fillet.p0 + [0 -lever_fillet];
gap_stop_init =  h_fillet.p1;
gap_stop_center = h_latch.p0(1);

h_fillet.p2 = h_latch.p0 + (h_latch.r(2)-.005)*[cos(lever_fillet_theta) sin(lever_fillet_theta)];

%Rotate P0,P1, and P2
h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
h_rot.p0 = h_latch.p0;
out=rotate_pts(h_rot);

h_fillet.p0 = out(1,:);
h_fillet.p1 = out(2,:);
h_fillet.p2 = out(3,:);
latch_fillet_r = fillet(h_fillet);

%Creates etch hole in fillet
if h_latch.noetch == 0
    h_cir.x = h_fillet.p0(1);
    h_cir.y = h_fillet.p0(2);
    h_cir.r = 2;
    h_cir.layer = 2;
    h_cir.n = 25;
    r_fillet_etch = circle(h_cir);
end




%% Serpentine spring and contact to rotor

%First add contact to rotor
if h_latch.compact_latch == 1 %Might want to switch to this for all latch setups
    contact_angle = pi/180*(h_latch.compact_ang1 - h_latch.init_angle - h_latch.orientation*(h_latch.actuation_angle + 63 - h_latch.manual_theta*180/pi));
else
    %Standard non-optimized latch
    contact_angle = pi/180*(360 - h_latch.theta_arm - h_latch.orientation*h_latch.actuation_angle);
end


contact_w = h_latch.ss_contact_w;          % Width of contact rod affixing serpentine to rotor/extension 
%s_spring_width = 4;     % Actual width of the meanders of the serpentine spring
s_spring_width = h_latch.ss.spring_w;
contact_l = 40;         % Projected length of contact 'rod' that attaches to either extension or rotor 
contact_l2 = 35;        % Actual length of contact 'rod' that attached to either extension or rotor 
snap = .35;             % A snapping parameter that makes sure there's no gap between the rotor and other components

if h_latch.chiplet == 1
    additional_theta =  -pi/3;
    contact_angle = contact_angle + additional_theta;
else
    contact_angle = contact_angle;
end


if h_latch.closed==0 
    h_rect.x = h_latch.p0(1) + (h_latch.r(2)-snap)*cos(contact_angle);
    h_rect.y = h_latch.p0(2) + (h_latch.r(2)-snap)*sin(contact_angle);
    h_rect.w = contact_w;
    h_rect.l = contact_l2+snap;
    h_rect.layer = 6;
    h_rect.theta = contact_angle-pi/2;
else
    h_rect.x = h_latch.p0(1) + (h_latch.r(2)-snap)*cos(contact_angle-latch_actuation_angle);
    h_rect.y = h_latch.p0(2) + (h_latch.r(2)-snap)*sin(contact_angle-latch_actuation_angle);
    h_rect.w = contact_w;
    h_rect.l = contact_l2+snap;
    h_rect.layer = 6;
    %h_latch.orientation
    h_rect.theta = contact_angle-pi/2 - latch_actuation_angle;
    contact_angle = contact_angle - latch_actuation_angle;
end

h_rect.p0 = [h_rect.x h_rect.y];
rotor_contact = rect(h_rect);
h_rect.rp = 1;
h_rect.l = contact_l;
rotor_contact_points = rect(h_rect);
h_rect.rp = 1;
h_rect.l = contact_l2;
rotor_contact_points2 = rect(h_rect);
h_rect.rp = 0;

c1p0 = midpt(rotor_contact_points2(1,:),rotor_contact_points2(2,:),.5);
c1p1 = midpt(rotor_contact_points2(3,:),rotor_contact_points2(4,:),.5);
c1p = midpt(rotor_contact_points(3,:),rotor_contact_points(4,:),.5);

%Add fillets to contact
%left
h_fillet.d = .5;
h_fillet.layer = 6;
h_fillet.radial_dist = pi/16;
h_fillet.axial_dist = 10;
h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(2,:),.01);

%lever_fillet_theta = atan2(h_arm.y+h_arm.l - h_latch.p0(2),h_arm.x+h_latch.armw - h_latch.p0(1)) + lever_fillet/h_latch.r(2);
h_fillet.p1 = h_latch.p0 + (h_latch.r(2)-snap)*[cos(contact_angle+h_fillet.radial_dist) sin(contact_angle+h_fillet.radial_dist)];
h_fillet.p2 =midpt(h_fillet.p0,rotor_contact_points(4,:),h_fillet.axial_dist/contact_l);

%Rotate P0,P1, and P2
h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
%h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
h_rot.theta = 0;
h_rot.p0 = h_latch.p0;
out=rotate_pts(h_rot);

h_fillet.p0 = out(1,:);
h_fillet.p1 = out(2,:);
h_fillet.p2 = out(3,:);
rot_cont_fillet_l = fillet(h_fillet);

%right
h_fillet.d = .5;
h_fillet.layer = 6;
h_fillet.radial_dist = pi/16;
h_fillet.axial_dist = 10;
ang2 = contact_w/h_latch.r(2);
h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(2,:),.99);

%lever_fillet_theta = atan2(h_arm.y+h_arm.l - h_latch.p0(2),h_arm.x+h_latch.armw - h_latch.p0(1)) + lever_fillet/h_latch.r(2);
h_fillet.p1 = h_latch.p0 + (h_latch.r(2)-snap)*[cos(contact_angle-h_fillet.radial_dist-ang2) sin(contact_angle-h_fillet.radial_dist-ang2)];
h_fillet.p2 = midpt(h_fillet.p0,rotor_contact_points(3,:),h_fillet.axial_dist/contact_l);

%Rotate P0,P1, and P2
h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
%h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
h_rot.theta = 0;
h_rot.p0 = h_latch.p0;
out=rotate_pts(h_rot);

h_fillet.p0 = out(1,:);
h_fillet.p1 = out(2,:);
h_fillet.p2 = out(3,:);
rot_cont_fillet_r = fillet(h_fillet);


if h_latch.chiplet ~= 1 %This is not a rotated chiplet that strikes with the lever arm
    
    %Create electrode contact
    dist_from_rotor = h_latch.ss.dist_from_rotor;      %Was 200 in original designs
    if (h_latch.zif && ~h_latch.no_backstops)
        probe_contact_w = 300;
    else
        probe_contact_w = 100;
    end
    extension_w = 25;
    extension_l = 50;
    
    % Makes contact for probe (large square)
    decrease_y = 60;                        % Pulls contact down vertically
    h_rect.x = h_latch.p0(1) + h_latch.orientation*(h_latch.r(2) + dist_from_rotor);
    h_rect.y = h_latch.p0(2) + h_latch.r(2)-extension_w/2 -probe_contact_w/2 + (probe_contact_w-extension_w)/2-decrease_y;
    h_rect.w = probe_contact_w*h_latch.orientation;
    h_rect.l = probe_contact_w;
    h_rect.layer = 6;
    h_rect.theta = -(latch_arm_initial_angle + pi/2);
    h_rect.p0 = h_latch.p0;
    probe_cont = rect(h_rect);
    
    %Find center of circle for serpentine spring  
    %y_val = h_latch.p0(2) + h_latch.r(2)-decrease_y;
  
    
    %Dummy fill for latch
    extra = 100;
    h_rect.x = h_latch.p0(1) - h_latch.orientation*(h_latch.r(2) + extra);
    h_rect.y = h_latch.p0(2) - h_latch.r(2)- extra-decrease_y - extra;
    h_rect.w = h_latch.orientation*(2*probe_contact_w + 2*h_latch.r(2) + dist_from_rotor+extra);
    h_rect.l =  2*h_latch.r(2) + 2*probe_contact_w+2*extra;
    h_rect.layer = 8;
    h_rect.theta = -(latch_arm_initial_angle + pi/2);
    %h_rect.theta = contact_angle-pi/2;
    h_rect.p0 = h_latch.p0;
    df_latch_1 = rect(h_rect);
    
              
    %Make extension 
    h_rect.x = h_latch.p0(1) + h_latch.orientation*(h_latch.r(2) + dist_from_rotor-extension_l);
    h_rect.y = h_latch.p0(2) + h_latch.r(2)-extension_w-decrease_y;
    h_rect.w = h_latch.orientation*extension_l;
    h_rect.l = extension_w;
    h_rect.layer = 6;
    %h_rect.theta =  -(latch_arm_initial_angle + h_latch.orientation*pi/2);
    h_rect.theta =  -(latch_arm_initial_angle + pi/2);
    h_rect.p0 = h_latch.p0;
    probe_cont_ext = rect(h_rect);
    
    %Add contact onto the extension
    h_rect.x = h_latch.p0(1) +  h_latch.orientation*(h_latch.r(2) + dist_from_rotor-extension_l/2.0);
    h_rect.y = h_latch.p0(2) + h_latch.r(2) - decrease_y;
    h_rect.w = h_latch.orientation*contact_w;
    h_rect.l = contact_l2;
    h_rect.layer = 6;
    h_rect.p0 = h_latch.p0;
    h_rect.theta =  -(latch_arm_initial_angle + pi/2);
    probe_extension_cont = rect(h_rect);
    
    h_rect.rp = 1;
    h_rect.l = contact_l;
    rotor_contact_points = rect(h_rect);
    h_rect.l = contact_l2;
    rotor_contact_points2 = rect(h_rect);
    h_rect.rp = 0;
    
    c2p0 = midpt(rotor_contact_points2(1,:),rotor_contact_points2(2,:),.5);
    c2p1 = midpt(rotor_contact_points2(3,:),rotor_contact_points2(4,:),.5);
    c2p = midpt(rotor_contact_points(3,:),rotor_contact_points(4,:),.5); %One side of serpentine spring
    
    
    
    %Add Fillets to the contact on the extension
    %right (for positive latch.orientation, left for negative orientation)
    h_fillet.d = .5;
    h_fillet.layer = 6;
    h_fillet.x_dist = 20;
    h_fillet.y_dist = 10;
    h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(2,:),.99);
    
    h_fillet.p1 = h_fillet.p0 + [h_latch.orientation*h_fillet.x_dist 0];
    h_fillet.p2 = h_fillet.p0 + [0 h_fillet.y_dist];
    
    %Rotate P0,P1, and P2
    h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
    h_rot.theta =  -(latch_arm_initial_angle + pi/2);
    h_rot.p0 = h_fillet.p0;
    out=rotate_pts(h_rot);
    
    h_fillet.p0 = out(1,:);
    h_fillet.p1 = out(2,:);
    h_fillet.p2 = out(3,:);
    ext_cont_fill_r = fillet(h_fillet);
    
    %left (for positive latch.orientation, right for negative)
    h_fillet.d = .5;
    h_fillet.layer = 6;
    h_fillet.x_dist = 20;
    h_fillet.y_dist = 10;
    h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(2,:),.01);
    
    h_fillet.p1 = h_fillet.p0 - [h_latch.orientation*h_fillet.x_dist 0];
    h_fillet.p2 = h_fillet.p0 + [0 h_fillet.y_dist];
    
    %Rotate P0,P1, and P2
    h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
    %h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
    h_rot.theta =  -(latch_arm_initial_angle + pi/2);
    h_rot.p0 = h_fillet.p0;
    out=rotate_pts(h_rot);
    
    h_fillet.p0 = out(1,:);
    h_fillet.p1 = out(2,:);
    h_fillet.p2 = out(3,:);
    ext_cont_fill_l = fillet(h_fillet);
    
    %Add serpentine spring connecting both contacts
    closeness = .05;
    
    cont2 = midpt(c1p,c2p,1-closeness); %Left end of serpentine
    cont1 = midpt(c1p,c2p,closeness);   %Right ened of serpentine
    %Flips the Serpentine Spring to make sure it has the high and low
    %meanders on the correct side
    if(h_latch.orientation == -1 && h_latch.gim==0)
        h_ss.p1 = cont1;
        h_ss.p2 = cont2;
    else
        h_ss.p1 = cont2;
        h_ss.p2 = cont1;
    end
    
    if(h_latch.flip_spring == 1)
        temp = h_ss.p1;
        h_ss.p1 = h_ss.p2;
        h_ss.p2 = temp; 
    end
    
    h_ss.n = h_latch.ss.n;                             %Used to be 6
    h_ss.w = s_spring_width;
    h_ss.dpp = h_latch.ss.dpp;                          %was 70 in the designs that worked
    h_ss.layer =6;
    
    if h_latch.ss_meander_spline ~= 1       %Will run when ss_meander_sline == 0 or 2
        serpentine = s_spring(h_ss);
        h_ss.rp = 1;
        if(h_latch.orientation == -1 && h_latch.gim==0)
            ss_points = s_spring(h_ss);
        else
            ss_points = flipud(s_spring(h_ss));
        end
        
        if(h_latch.flip_spring == 1)
            ss_points = flipud(ss_points);
        end
    end
    
    if h_latch.ss_meander_spline == 1 || h_latch.ss_meander_spline == 2 %Will run when == 1 or 2
        %Makes contacts curvey instaead of intersecting at 90deg
        %Return points from above
        h_ss.rp = 1;
        ss_points = s_spring(h_ss);
        
        %Now smooth out all the points
        final_ss_points = [c1p0;ss_points;c2p0]';
        init_points = final_ss_points;
        interm_pts = fnplt(cscvn(init_points));
        points = [interm_pts'];
        temp = gds_element('path', 'xy',points,'width',s_spring_width,'layer',h_fillet.layer);
        str_name = sprintf('SS_Spline_[%d,%d]',round(cont1(1)),round(cont1(2)));
        serpentine_spline_meanders = gds_structure(str_name,temp);
    end
    
    %Add spline fits from the contacts to the springs
    %left
    serpentine_radius = 80;
    
    c_int_t = midpt(c1p0,c2p0,.3);
    c_int_b = midpt(c1p1,c2p1,.3);
    
    ang = atan((c_int_t(2)-c_int_b(2))/(c_int_t(1)-c_int_b(1)));
    
    c_int = c_int_b + serpentine_radius*[sin(ang) cos(ang)];
    
    
    init_points = [c1p0', c1p1', c_int', c2p1', c2p0'];
    
    interm_pts = fnplt(cscvn(init_points));
    
    final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),2) interm_pts(1,end);
        interm_pts(2,1) downsample(interm_pts(2,2:end-1),2) interm_pts(2,end)];
    
    %points = [final_pts'];
    %temp = gds_element('path', 'xy',points,'width',contact_w,'layer',h_fillet.layer);
    %str_name = sprintf('Spline_[%d,%d]',round(c1p1(1)),round(c1p1(2)));
    %serpentine_spline_l = gds_structure(str_name,temp);
    
        %Add spline fits from the contacts to the springs
    %left
    
    init_points = [c1p0', c1p1', ss_points(1,:)', ss_points(2,:)'];
    
    interm_pts = fnplt(cscvn(init_points));
    
    final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),2) interm_pts(1,end);
        interm_pts(2,1) downsample(interm_pts(2,2:end-1),2) interm_pts(2,end)];
    
    points = [final_pts'];
    temp = gds_element('path', 'xy',points,'width',mean([contact_w s_spring_width]),'layer',h_fillet.layer);
    str_name = sprintf('Spline_[%d,%d]',round(c1p1(1)),round(c1p1(2)));
    serpentine_spline_l = gds_structure(str_name,temp);
    
    %right
    extrapt1 = midpt(c2p0,c2p1,.5);
    extrapt11 = midpt(c2p0,c2p1,.85);
    extrapt2 = midpt(ss_points(end,:),ss_points(end-1,:),.5);
    %init_points = [c2p0',extrapt1',extrapt11',c2p1', ss_points(end,:)', extrapt2',ss_points(end-1,:)'];
    init_points = [c2p0',extrapt1',extrapt11',c2p1', ss_points(end,:)', extrapt2',ss_points(end-1,:)'];
    
    interm_pts = fnplt(cscvn(init_points));
    
    final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),2) interm_pts(1,end);
        interm_pts(2,1) downsample(interm_pts(2,2:end-1),2) interm_pts(2,end)];
    
    points = [final_pts'];
    temp = gds_element('path', 'xy',points,'width',mean([contact_w s_spring_width]),'layer',h_fillet.layer);
    str_name = sprintf('Spline_[%d,%d]',round(c2p1(1)),round(c2p1(2)));
    serpentine_spline_r = gds_structure(str_name,temp);
    

    
else %This is for V1 Hammer Chiplet (strikes membrane with lever arm)
    
    %Create electrode contact
    dist_from_rotor = 200;
    probe_contact_w = 100;
    extension_w = 25;
    extension_l = 50;
   
    % Creates the probe contact (large square)
    h_rect.x = h_latch.p0(1) + h_latch.r(2) + dist_from_rotor;
    h_rect.y = h_latch.p0(2) + h_latch.r(2)-extension_w/2 -probe_contact_w/2 + h_latch.orientation*(probe_contact_w-extension_w)/2;
    h_rect.w = probe_contact_w;
    h_rect.l = probe_contact_w;
    h_rect.layer = 6;
    h_rect.theta = -(latch_arm_initial_angle + h_latch.orientation*pi/2)+additional_theta;
    %h_rect.theta = contact_angle-pi/2;
    h_rect.p0 = h_latch.p0;
    probe_cont = rect(h_rect);
    
    %Add contact spring onto the probe pad
    h_rect.x = h_latch.p0(1) + h_latch.r(2) + dist_from_rotor;
    %h_rect.y = h_latch.p0(2) + h_latch.r(2) - extension_w/2.0 + h_latch.orientation*extension_w/2.0;
    h_rect.y = h_latch.p0(2) + h_latch.r(2)-extension_w + probe_contact_w/2.0;
    h_rect.w = -contact_l2*h_latch.orientation;
    h_rect.l = contact_w;
    h_rect.layer = 6;
    h_rect.p0 = h_latch.p0;
    h_rect.theta =  -(latch_arm_initial_angle + h_latch.orientation*pi/2)+additional_theta;
    probe_extension_cont = rect(h_rect);
    h_rect.rp = 1;
    h_rect.l = contact_w;
    rotor_contact_points = rect(h_rect);
    h_rect.l = contact_w;
    rotor_contact_points2 = rect(h_rect);
    h_rect.rp = 0;
    
    c2p0 = midpt(rotor_contact_points2(1,:),rotor_contact_points2(4,:),.5);
    c2p1 = midpt(rotor_contact_points2(2,:),rotor_contact_points2(3,:),.5);
    c2p = midpt(rotor_contact_points(3,:),rotor_contact_points(4,:),.5);
    
    %Add Fillets to the contact on the extension
    %right/top
    h_fillet.d = .5;
    h_fillet.layer = 6;
    h_fillet.x_dist = 20;
    h_fillet.y_dist = 10;
    h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(4,:),.99);
    
    h_fillet.p1 = h_fillet.p0 - [h_fillet.x_dist 0];
    h_fillet.p2 = h_fillet.p0 + [0 h_latch.orientation*h_fillet.y_dist];
    
    %Rotate P0,P1, and P2
    h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
    %h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
    h_rot.theta =  -(latch_arm_initial_angle + h_latch.orientation*pi/2)+additional_theta;
    %h_rot.theta = 0;
    h_rot.p0 = h_fillet.p0;
    out=rotate_pts(h_rot);
    
    h_fillet.p0 = out(1,:);
    h_fillet.p1 = out(2,:);
    h_fillet.p2 = out(3,:);
    ext_cont_fill_r = fillet(h_fillet);
    
    %left
    h_fillet.d = .5;
    h_fillet.layer = 6;
    h_fillet.x_dist = 20;
    h_fillet.y_dist = 10;
    h_fillet.p0 =  midpt(rotor_contact_points(1,:),rotor_contact_points(4,:),.01);
    
    h_fillet.p1 = h_fillet.p0 - [h_fillet.x_dist 0];
    h_fillet.p2 = h_fillet.p0 - [0 h_latch.orientation*h_fillet.y_dist];
    
    %Rotate P0,P1, and P2
    h_rot.pts = [h_fillet.p0;h_fillet.p1;h_fillet.p2];
    %h_rot.theta = -(h_latch.theta_arm + 90)*pi/180;
    h_rot.theta =  -(latch_arm_initial_angle + h_latch.orientation*pi/2)+additional_theta;
    h_rot.p0 = h_fillet.p0;
    out=rotate_pts(h_rot);
    
    h_fillet.p0 = out(1,:);
    h_fillet.p1 = out(2,:);
    h_fillet.p2 = out(3,:);
    ext_cont_fill_l = fillet(h_fillet);
    
    %Add serpentine spring connecting both contacts
    closeness = .1;
    
    cont2 = midpt(c1p,c2p,1-1.5*closeness);
    cont1 = midpt(c1p,c2p,closeness);
    h_ss.p1 = cont1;
    h_ss.p2 = cont2;
    h_ss.n = 5;
    h_ss.w = s_spring_width;
    h_ss.dpp = 80;
    h_ss.layer = 6;
    serpentine = s_spring(h_ss);
    h_ss.rp = 1;
    ss_points = s_spring(h_ss);
    
    
    %Add spline fits from the contacts to the springs
    %left
    
    init_points = [c1p0', c1p1', ss_points(1,:)', ss_points(2,:)'];
    
    interm_pts = fnplt(cscvn(init_points));
    
    final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),2) interm_pts(1,end);
        interm_pts(2,1) downsample(interm_pts(2,2:end-1),2) interm_pts(2,end)];
    
    points = [final_pts'];
    temp = gds_element('path', 'xy',points,'width',mean([contact_w s_spring_width]),'layer',h_fillet.layer);
    str_name = sprintf('Spline_[%d,%d]',round(c1p1(1)),round(c1p1(2)));
    serpentine_spline_l = gds_structure(str_name,temp);
    
    %right
    extrapt1 = midpt(c2p0,c2p1,.5);
    extrapt11 = midpt(c2p0,c2p1,.85);
    extrapt2 = midpt(ss_points(end,:),ss_points(end-1,:),.5);
    %init_points = [c2p0',extrapt1',extrapt11',c2p1', ss_points(end,:)', extrapt2',ss_points(end-1,:)'];
    init_points = [c2p0',extrapt1',extrapt11',c2p1', ss_points(end,:)', extrapt2',ss_points(end-1,:)'];
    
    interm_pts = fnplt(cscvn(init_points));
    
    final_pts = [interm_pts(1,1) downsample(interm_pts(1,2:end-1),2) interm_pts(1,end);
        interm_pts(2,1) downsample(interm_pts(2,2:end-1),2) interm_pts(2,end)];
    
    points = [final_pts'];
    temp = gds_element('path', 'xy',points,'width',mean([contact_w s_spring_width]),'layer',h_fillet.layer);
    str_name = sprintf('Spline_[%d,%d]',round(c2p1(1)),round(c2p1(2)));
    serpentine_spline_r = gds_structure(str_name,temp);
end


%% Main Electrode and gap stops

if h_latch.chiplet ~=1
    gap_stop_width = 100;
else
    gap_stop_width = 150;
end

electrode_gapstop_gap = 30;


electrode_w = 200;
if h_latch.alumina == 0;
    electrode_gap = .5; %Gap between closed lever arm and electrode
else
    electrode_gap = 0; %Gap between closed lever arm and electrode
end



if h_latch.chiplet ~= 1 && h_latch.no_backstops == 0
    %Create top gap stop
    h_rect.x = gap_stop_center + h_latch.orientation*h_latch.armw/2;
    h_rect.y = gap_stop_init(2) - gap_stop_width;
    h_rect.w = gap_stop_width*h_latch.orientation;
    h_rect.l = gap_stop_width;
    h_rect.layer = 6;
    h_rect.p0 = h_latch.p0;
    %h_rect.theta = latch_actuation_angle+latch_arm_initial_angle;
    %h_rect.theta = latch_actuation_angle;
    h_rect.theta = -(latch_arm_initial_angle+pi/2) + latch_actuation_angle*h_latch.orientation;
    if h_latch.alumina ==0
        top_gap_stop = rect(h_rect);
    end
end

% Bottom gap stop
h_rect.x = gap_stop_center + h_latch.orientation*h_latch.armw/2;
h_rect.y = h_arm.y;
h_rect.w = gap_stop_width*h_latch.orientation;
h_rect.l = gap_stop_width;
h_rect.layer = 6;
h_rect.p0 = h_latch.p0;
%h_rect.theta = latch_actuation_angle+latch_arm_initial_angle;
%h_rect.theta = latch_actuation_angle;
h_rect.theta = -(latch_arm_initial_angle+pi/2)+ latch_actuation_angle*h_latch.orientation;
if h_latch.alumina == 0 && h_latch.no_backstops == 0
    bot_gap_stop = rect(h_rect);
end
h_rect.rp = 1;
bot_gap_stop_pts = rect(h_rect);
h_rect.rp = 0;



% Dummy fill for bottom gap stop
extra = 100;
h_rectdf.x = gap_stop_center + h_latch.orientation*(h_latch.armw/2 - extra);
h_rectdf.y = h_arm.y - extra;
h_rectdf.w = (electrode_w + 2*extra)*h_latch.orientation;
h_rectdf.l = 2*extra + 2*gap_stop_width + gap_stop_init(2) - gap_stop_width - (h_arm.y + gap_stop_width + electrode_gapstop_gap) + electrode_gapstop_gap;
h_rectdf.layer = 8;
h_rectdf.p0 = h_latch.p0;
%h_rectdf.theta = -(latch_arm_initial_angle+pi/2)+ latch_actuation_angle*h_latch.orientation;
h_rectdf.theta = -(latch_arm_initial_angle_2+pi/2)+ latch_actuation_angle*h_latch.orientation;
h_rectdf.rp = 0;
df_electrode = rect(h_rectdf);



if h_latch.cstage == h_latch.stages
    h_mlatch.p0 = [h_rect.x+h_rect.w h_rect.y];
    h_mlatch.gap_stop_width = gap_stop_width;
    h_mlatch.t = 10;
    h_mlatch.arm_w = h_latch.armw;
    h_mlatch.rot_p0 = h_latch.p0;
    h_mlatch.theta =  -(latch_arm_initial_angle+pi/2)+ latch_actuation_angle*h_latch.orientation;
    h_mlatch.layer = 6;
    h_mlatch.orientation = h_latch.orientation;
    
    if (h_latch.alumina == 0 && h_latch.mech_latch == 1)
        mechanical_latch = mech_latch(h_mlatch);
    end
    % Function to create the mechanical latch
    % p0 = Bottom right point on the latch (where it touches the gap stop)
    % gap_stop_width = width of the gap stop
    % arm_w = width of lever arm
    
    % theta = angle by which to rotate rectangle
    % rot_p0 = point about which to rotate
    % rp = return points, if rp==1, returns column vector of verticies
end





if (h_latch.chiplet ~= 1 && ~h_latch.no_backstops)
    %Create long electrode
    %h_rect.x = gap_stop_init(1) + electrode_gap;
    h_rect.x = gap_stop_center + h_latch.orientation*(h_latch.armw/2+electrode_gap);
    h_rect.y = h_arm.y + gap_stop_width + electrode_gapstop_gap;
    h_rect.w = electrode_w*h_latch.orientation;
    if h_latch.alumina
        h_rect.l = gap_stop_init(2) - (h_arm.y + electrode_gapstop_gap) - 40;
        h_rect.y = h_arm.y;
    else
        h_rect.l = gap_stop_init(2) - gap_stop_width - (h_arm.y + gap_stop_width + electrode_gapstop_gap) - electrode_gapstop_gap; 
    end
    h_rect.layer = 6;
    h_rect.p0 = h_latch.p0;
    %h_rect.theta = latch_actuation_angle+latch_arm_initial_angle;
    %h_rect.theta = latch_actuation_angle;
    h_rect.theta = -(latch_arm_initial_angle_2+pi/2)+ latch_actuation_angle*h_latch.orientation;
    h_rect.rounded = 25;
    
    latch_electrode = rect(h_rect);
    h_rect.rp = 1;
    pts = rect(h_rect);
    h_rect.rp = 0;
    
    %Adds contact to electrode for silver epoxy wire
    if h_latch.zif && h_latch.compact_latch
        h_rect.layer = 6;
        h_rect.x = pts(round(3*h_rect.rounded),1)-h_rect.rounded;
        h_rect.y = pts(round(3*h_rect.rounded),2)-h_rect.rounded;
        h_rect.l = 300;
        h_rect.w = 300;
        h_rect.rounded = 10;
        h_rect.theta = 0;
        epoxy_electrode = rect(h_rect);
        
        %Add not dummy
        h_rect.x = h_rect.x -50;
        h_rect.y = h_rect.y -50;
        h_rect.l = 400;
        h_rect.w = 400;
        h_rect.layer = 8;
        df_epoxy_electrode = rect(h_rect);
        
        %Add path towards end of chiplet
        w = 30;
        p1 = pts(round(3*h_rect.rounded),:)-h_rect.rounded + [210 300-10];
        p2 = p1 - [850 0];
        p3 = p2 - [0 1700];  
        
        points = [p1;p2;p3];
        be = gds_element('path', 'xy',points,'width', w,'layer',6);
        str_name = sprintf('_p[%d,%d],[%d,%d]',round(p1(1)),round(p1(2)),round(p2(1)),round(p2(2)));
        pathhh = gds_structure(str_name,be);
        
        be = gds_element('path', 'xy',points,'width', w+30,'layer',8);
        str_name = sprintf('_p2[%d,%d],[%d,%d]',round(p1(1)),round(p1(2)),round(p2(1)),round(p2(2)));
        df_pathhh = gds_structure(str_name,be);
        
        %Other pad at the end of the chiplet
        h_rect.layer = 6;
        h_rect.l = 400;
        h_rect.w = 400;
        h_rect.x = p3(1)-h_rect.w/2;
        h_rect.y = p3(2)-h_rect.l/2;

        h_rect.rounded = 10;
        h_rect.theta = 0;
        epoxy_electrode22 = rect(h_rect);
        
        %Add not dummy
        h_rect.x = h_rect.x -50;
        h_rect.y = h_rect.y -50;
        h_rect.l = 500;
        h_rect.w = 500;
        h_rect.layer = 8;
        df_epoxy_electrode22 = rect(h_rect);
        
    elseif h_latch.zif
        
        % Makes large pad on final 
        h_rect.layer = 6;
        h_rect.x = pts(round(3*h_rect.rounded),1)-h_rect.rounded-200;
        h_rect.y = pts(round(3*h_rect.rounded),2)+h_rect.rounded-200;
        h_rect.l = 200;
        h_rect.w = 200;
        h_rect.rounded = 10;
        h_rect.theta = 0;
        epoxy_electrode = rect(h_rect);
        
        
        relay_contact = [h_rect.x+h_rect.l h_rect.y+h_rect.l/2];
        
        %Add relay here
        if h_latch.vapr_relay == 1
            
            h_relay = h_latch.h_relay;
            
            h_relay.p0 = relay_contact;
            %h_relay.contact_type = 1;
            %h_relay.contact_head_type = 1;
            %h_relay.springw = 5;
            %h_relay.dc_offset = 3;
            vapr_relay_1 = Vapr_relay(h_relay);
        end
        
        
               
        %Add not dummy
        h_rect.x = h_rect.x - 150;
        h_rect.y = h_rect.y - 150;
        h_rect.l = 700;
        h_rect.w = 700;
        h_rect.layer = 8;
        df_epoxy_electrode = rect(h_rect);
        

        

    end

end

backside_trench_len = [0 2*h_latch.r(2) + h_latch.arml + 250]; %250 is from the latch function





%% Grab all the GDS structures and arrays of structures

%Find all gds structures
a=whos();
b={};
c = 0;
for i=1:length(a)
    if(strcmp(a(i).class,'gds_structure'))
        c = c+1;
        str = sprintf('b{c} = %s;',a(i).name);
        eval(str);
    elseif(strcmp(a(i).class,'cell'))
        str = sprintf('temp = %s;',a(i).name);
        eval(str);
        if(isempty(temp))
            fprintf('Empty Cell! Something went wrong with %s!!\n',a(i).name)
            break;
        end
        str = sprintf('strcmp(class(%s{1}),''gds_structure'');',a(i).name);
        if(eval(str))
            str = sprintf('temp = %s;',a(i).name);
            eval(str)
            for i=1:length(temp)
                c = c+1;
                b{c} = temp{i};
            end
        end
    end
end

% Outputs a cell array of
out = b;

pts_out = [backside_trench_len;bot_gap_stop_pts(4,:);bot_gap_stop_pts(2,:);latch_arm_pt];
