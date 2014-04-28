% HW #:      Final Project Competition
% name:      Sam Stern, Harrison Mace
% ID:        maceh
% date:      04-29-2014


%% -- Info --

%   Subject 1
%   I521_A0009_D001 - Training ECoG
%   I521_A0009_D002 - Training Data Glove
%   I521_A0009_D003 - Testing ECoG

%   Subject 2
%   I521_A0010_D001 - Training ECoG
%   I521_A0010_D002 - Training Data Glove
%   I521_A0010_D003 - Testing ECoG

%   Subject 3
%   I521_A0011_D001 - Training ECoG
%   I521_A0011_D002 - Training Data Glove
%   I521_A0011_D003 - Testing ECoG


%% -- Mine Data --

clear all;

% make a user input for pennkey?
% passwordfile must be in current directory (CD)
% .mat file stored in CD 

% get session data
disp('');
disp('Acquiring Training ECoG data');
sub1_train_ecog = IEEGSession('I521_A0009_D001','maceh','maceh_IEEG_passwordFile');
sub2_train_ecog = IEEGSession('I521_A0010_D001','maceh','maceh_IEEG_passwordFile');
sub3_train_ecog = IEEGSession('I521_A0011_D001','maceh','maceh_IEEG_passwordFile');

disp('Acquiring Training Data Glove data');
sub1_train_dg = IEEGSession('I521_A0009_D002','maceh','maceh_IEEG_passwordFile');
sub2_train_dg = IEEGSession('I521_A0010_D002','maceh','maceh_IEEG_passwordFile');
sub3_train_dg = IEEGSession('I521_A0011_D002','maceh','maceh_IEEG_passwordFile');

disp('Acquiring Testing ECoG data');
sub1_test_ecog = IEEGSession('I521_A0009_D003','maceh','maceh_IEEG_passwordFile');
sub2_test_ecog = IEEGSession('I521_A0010_D003','maceh','maceh_IEEG_passwordFile');
sub3_test_ecog = IEEGSession('I521_A0011_D003','maceh','maceh_IEEG_passwordFile');

% save data as .mat file
save('all_data');
disp('Done.');


%%

all_data = load('all_data');

%% -- Signal Pre-Processing --
