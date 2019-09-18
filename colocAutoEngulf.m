%% ObjectFinder - Recognize 3D structures in image stacks
%  Copyright (C) 2016-2019 Luca Della Santina
%
%  This file is part of ObjectFinder
%
%  ObjectFinder is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
% *Colocalization - Automatic overlap analysis between engulfing/engilfed*
% Required parameters
%    srcDots        = Reference engulfing objects
%    dstDots        = Destination objects engulfed by srcDots
%    NumVoxOverlap  = Number of overlapping voxels between each objet and
%                     the binary mask to consider the object as colocalized
%    NumPercOverlap = Number of overlapping voxels between each objet and
%                     the binary mask expressed as percentage of Dots size
%                     to consider the object as colocalized

function ColocAuto = colocAutoEngulf(srcDots, dstDots, NumVoxOverlap, NumPercOverlap, WithinDist, CenterMustOverlap)
%%
ColocAuto.Source = srcDots.Name;
ColocAuto.Fish1  = dstDots.Name;

AutoColocAnalyzingFlag                      = ones([1,numel(srcDots.Vox)], 'uint8');
ColocAuto.ListDotIDsManuallyColocAnalyzed   = find(AutoColocAnalyzingFlag == 1);
ColocAuto.TotalNumDotsManuallyColocAnalyzed = length(ColocAuto.ListDotIDsManuallyColocAnalyzed);
ColocAuto.ColocFlag                         = zeros([1,ColocAuto.TotalNumDotsManuallyColocAnalyzed], 'uint8');

% Trasverse each reference object and count how many objects are engulfed
% *IMPORTANT*: ColocAuto here stores the absolute number of dstDots that 
% each srcDot is engulfing (after verifying overlap is more than threshold)

xyum = srcDots.Settings.ImInfo.xyum;
zum  = srcDots.Settings.ImInfo.zum;

for idx_src = 1:numel(srcDots.Vox)
    if ~srcDots.Filter.passF(idx_src)
        ColocAuto.ColocFlag(idx_src) = -1; % Invalid dot
        continue
    end
   
    for idx_dst = 1:numel(dstDots.Vox)
        if ~dstDots.Filter.passF(idx_dst)
            continue
        end
        
        if CenterMustOverlap        
            % Calculate brightness peak position because dstDots.Pos(i,:) might not
            % be any of the actual pixels listed in dstDots.Vox(i).Pos
            BrightPeakPos = dstDots.Vox(idx_dst).Ind(dstDots.Vox(idx_dst).RawBright == max(dstDots.Vox(idx_dst).RawBright));
            if size(BrightPeakPos,1) > 1
                BrightPeakPos = BrightPeakPos(1,:);
            end
        
            % Check whether the center voxel of dstDot is among the voxels belonging to srcDot
            if isempty(find(srcDots.Vox(idx_src).Ind == BrightPeakPos, 1))
                continue
            end
        end               
        
        VoxOverlap     = numel(intersect(srcDots.Vox(idx_src).Ind, dstDots.Vox(idx_dst).Ind));
        VoxOverlapPerc = 100 * VoxOverlap / dstDots.Vol(idx_dst); % Store voxel overlap as percent of engulfed object volume
        PeakDistxy     = hypot( (srcDots.Pos(idx_src,1)-dstDots.Pos(idx_dst,1))*xyum, (srcDots.Pos(idx_src,2)-dstDots.Pos(idx_dst,2))*xyum);
        PeakDistxyz    = hypot( PeakDistxy, (srcDots.Pos(idx_src,3)-dstDots.Pos(idx_dst,3))*zum); % calculate separately along Z because this dimension has different pixel size
        
        if (VoxOverlap >= NumVoxOverlap) && (VoxOverlapPerc >= NumPercOverlap) && (PeakDistxyz <= WithinDist)
            ColocAuto.ColocFlag(idx_src) = ColocAuto.ColocFlag(idx_src) + 1; % Add one more engulfed
        end
    end
end

ColocAuto.NumDotsColoc      = length(find(ColocAuto.ColocFlag > 0));
ColocAuto.NumDotsNonColoc   = length(find(ColocAuto.ColocFlag == 0));
ColocAuto.NumFalseDots      = length(find(ColocAuto.ColocFlag < 0));
ColocAuto.ColocRate         = ColocAuto.NumDotsColoc/(ColocAuto.NumDotsColoc+ColocAuto.NumDotsNonColoc);
ColocAuto.FalseDotRate      = ColocAuto.NumFalseDots/(ColocAuto.NumDotsColoc+ColocAuto.NumDotsNonColoc+ColocAuto.NumFalseDots);
ColocAuto.ColocRateInclugingFalseDots = ColocAuto.NumDotsColoc/(ColocAuto.NumDotsColoc+ColocAuto.NumDotsNonColoc+ColocAuto.NumFalseDots);
ColocAuto.Method            = 'AutoEngulf';
ColocAuto.NumVoxOverlap     = NumVoxOverlap;
ColocAuto.NumPercOverlap    = NumPercOverlap;
end