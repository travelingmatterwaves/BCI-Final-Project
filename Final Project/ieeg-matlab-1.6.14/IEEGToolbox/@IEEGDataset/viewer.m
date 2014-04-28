function h = viewer(obj, varargin)
    %VIEWER  GUI which displays raw data and events.
    %    VIEWER(OBJ, RANGE, INDECES) creates a GUI which shows the
    %    electrodes INDECES over the range RANGE=[first_index last_index]
    %    for the IEEGDATASET object.
    %
    %    <USER INTERFACE>
    %    The default interface has buttons for paging forward/backward.
    %    Increasing/decreasing the y-scale. Increasing/decreasing the
    %    x-scale, and re-centering the data. 
    %
    %    The viewer does not filter any of the data and decimates the
    %    original data to match the displayed data to the available pixels
    %    on the screen. Note that this can cause aliassing (Future versions
    %    might include anti-aliassing filters).
    %
    %     <PAGING BETWEEN ANNOTATIONS>
    %    If the IEEGDATASET object has one or more ANNOTATIONLAYERS, they
    %    can be selected as event-page source and the user can page between
    %    annotations of the selected source using the event-forward and
    %    event-backward buttons. A vertical dotted line indicates the
    %    aligned event in the viewer.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright 2013 Trustees of the University of Pennsylvania
    % 
    % Licensed under the Apache License, Version 2.0 (the "License");
    % you may not use this file except in compliance with the License.
    % You may obtain a copy of the License at
    % 
    % http://www.apache.org/licenses/LICENSE-2.0
    % 
    % Unless required by applicable law or agreed to in writing, software
    % distributed under the License is distributed on an "AS IS" BASIS,
    % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    % See the License for the specific language governing permissions and
    % limitations under the License.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    assert(length(varargin{1})==2,...
      'VIEWER: RANGE must be a vector with length==2 ([start stop]).');
    
    
    panelColor = get(0,'DefaultUicontrolBackgroundColor');
    scrSize = (get(0,'ScreenSize')./72)./2.54;
    
    assert(nargin > 2, 'Insufficient number of input arguments.');

    sampleFreq = 1;
    xTitle = 'SampleNr';
    annLayers = obj.annLayer;
    
    % If more than standard number of input argument, then check inputs. This
    % fails if the user wants to pass 'sf' to the getData method or if the user
    % wants to pass an annotation structure to the getdata method. This should
    % never really happen.
    getDataAttr  = {};
    
    % Find Samplefreq, only if all channels have equal sample freq.
    allSF = [obj.channels.sampleRate];
    if all(allSF == allSF(1))
      sampleFreq = allSF(1);
      xTitle = 'Time (s)';
    else
      warning(['Not all channels are sampled at the same rate, '...
        'Using sample index for x-axis.']);
    end
    
    % Set up the figure and defaults
    uihandle = figure('Units','centimeters',...
      'Position',[scrSize(3)/1.25 scrSize(4)/4 30 20],...
      'Color',panelColor,...
      'Renderer','painters',...
      'HandleVisibility','callback',...
      'IntegerHandle','off',...
      'Toolbar','none',...
      'MenuBar','none',...
      'NumberTitle','off',...
      'Name','Workspace Plotter',...
      'ResizeFcn',@figResize);
    
    % Create the bottom uipanel
    topPanel = uipanel('BorderType','line',...
      'BackgroundColor',panelColor,...
      'Units','centimeters',...
      'Position',[1 1 11 1.2],...
      'Parent',uihandle,...
      'Clipping','on',...
      'Tag','topP',...
      'ResizeFcn',@topPanelResize);
    
    % Create the bottom uipanel
    bottomPanel = uipanel('BorderType','line',...
      'BackgroundColor',panelColor,...
      'Units','centimeters',...
      'Position',[1 1 11 1.2],...
      'Parent',uihandle,...
      'Clipping','on',...
      'Tag','botP',...
      'ResizeFcn',@botPanelResize);
    
    % Create the bottom uipanel
    bottomPanel2 = uipanel('BorderType','line',...
      'BackgroundColor',panelColor,...
      'Units','centimeters',...
      'Position',[1 1 11 1.2 ],...
      'Parent',uihandle,...
      'Clipping','on',...
      'Tag','botP2',...
      'ResizeFcn',@botPanelResize);
    
    % Create the right side panel
    centerPanel = uipanel('bordertype','line',...
      'BackgroundColor',panelColor,...
      'Units','centimeters',...
      'Position',[1/20 8 88 27],...
      'Parent',uihandle,...
      'Tag','cenP',...
      'ResizeFcn',@cenPanelResize);
    
    chanIndeces = varargin{2};
    chanLabels = cell(length(chanIndeces),1);
    for i=1:length(chanLabels)
      
%       chanLabels{i} = sprintf('Ch_%i',varargin{2}(i));
      chanLabels{i} = obj.channels(chanIndeces(i)).label;
    end
    
    % Create the center panel
    a1 = axes(...
      'Units','centimeters',...
      'Position', [3 2 88 27],...
      'XLim',[0 1],'YLim',[0,1],...
      'Tag','plotWindow',...
      'Parent',centerPanel,...
      'YTickLabel',chanLabels,'YTickLabelMode','manual','YTick',1:length(varargin{2}));
    set(get(a1,'XLabel'),'String',xTitle,'FontSize',12);
    set(get(a1,'YLabel'),'String','Channel Label','FontSize',12);

    if sampleFreq ~= 1
      plotName = sprintf('Dataset Name: %s\nSampling Rate: %3.2f', ...
        obj.snapName, sampleFreq);
    else
      plotName = sprintf(['Dataset Name: %s\nSampling Rate: '...
        'Varies per channel'], obj.snapName);
    end
    
    uicontrol(uihandle,'Style', 'text', 'Units','normalized', 'String', plotName,...
    'Position', [0 0 0.25 1], 'Parent', topPanel,'HorizontalAlignment','left',...
    'FontSize',12,'Tag','title');  

    uicontrol(uihandle,'Style', 'text', 'Units','centimeters', 'String', '[  ../div]',...
    'Position', [0.05 0.95 0.25 0.05], 'Parent', centerPanel,'HorizontalAlignment','left',...
    'FontSize',12,'Tag','y-scale');  
  
    uicontrol(uihandle,'Style', 'text', 'Units','centimeters', 'String', '[Decimation : -]',...
    'Position', [0.08 0.95 0.25 0.05], 'Parent', centerPanel,'HorizontalAlignment','left',...
    'FontSize',12,'Tag','decimation');  
  
    uicontrol(uihandle,'Style', 'text', 'Units','centimeters', 'String', '[Filter : -]',...
    'Position', [1.11 0.95 0.25 0.05], 'Parent', centerPanel,'HorizontalAlignment','left',...
    'FontSize',12,'Tag','filter'); 

    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', '<',...
    'Position', [0.1 0.1 2.4 1], 'Callback',@PushBackwards, 'Parent', bottomPanel);
    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', '>',...
    'Position', [2.6 0.1 2.4 1], 'Callback',@PushForwards,'Parent',bottomPanel);

    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', 'Ctr',...
    'Position', [6 0.1 2 1], 'Callback',@Center,'Parent',bottomPanel);
    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters','String', '-',...
    'Position', [8.1 0.1 2 1], 'Callback',@ZoomOutY,'Parent',bottomPanel);    
    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', '+',...
    'Position', [10.2 0.1 2 1], 'Callback',@ZoomInY,'Parent',bottomPanel);

    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', '><',...
    'Position', [12.3 0.1 2 1], 'Callback',@ZoomInT,'Parent',bottomPanel);
    uicontrol(uihandle,'Style', 'pushbutton','Units','centimeters', 'String', '<>',...
    'Position', [14.4 0.1 2 1], 'Callback',@ZoomOutT,'Parent',bottomPanel);

    uicontrol(uihandle,'Style', 'pushbutton', 'Units','centimeters', 'String', '<-|',...
    'Position', [17.4 0.1 2 1], 'Callback',{@NextEvnt,false},'Parent',bottomPanel);
    evntSelect = uicontrol(uihandle,'Style', 'pushbutton','Units','centimeters',...
    'Position', [19.5 0.1 3 1], 'Callback',@ToggleNEventButton,'Parent',bottomPanel,...
    'ForegroundColor', [0.4 0.4 0.4],'Tag','EvntSelect','userData',0);
    uicontrol(uihandle,'Style', 'pushbutton','Units','centimeters', 'String', '|->',...
    'Position', [22.6 0.1 2 1], 'Callback',{@NextEvnt,true},'Parent',bottomPanel);

    uicontrol(uihandle,'Style', 'pushbutton','Units','centimeters', 'String', 'To PDF',...
    'Position', [24.6 0.1 2.4 1], 'Callback',@PrintPDF,'Parent',topPanel, 'Tag','pdfButton');

    uicontrol(uihandle,'Style', 'pushbutton','Units','centimeters', 'String', 'Decimation On',...
    'Position', [24.6 0.1 3 1], 'Callback',@EnableDec,'Parent',topPanel, 'Tag','decButton',...
    'ForegroundColor',[0 0.5 0]);
  

    if ~isempty(annLayers)
      evButtonHandles = zeros(length(annLayers),1);
      for iLayer = 1:length(annLayers)
   
        evButtonHandles(iLayer) = uicontrol(uihandle, ...
          'Style', 'pushbutton', ...
          'Units','centimeters', ...
          'String', annLayers(iLayer).name, ...
          'Position', [(0.1 + (iLayer-1)*4.8 + (iLayer-1)*0.1) 0.1 4.8 1], ...
          'Tag', annLayers(iLayer).name, ...
          'Callback',@toggleEventButton, ...
          'Parent',bottomPanel2, ...
          'userData',{0 annLayers(iLayer) iLayer []}); % [Vismode IEEGLayer LayerIndex, [AllstartTimes] ]
      end
    else
      evButtonHandles = [];
    end
    
    set(evntSelect,'String','-');
    
	% Create Line handles
    lHandles = zeros(size(varargin{2},2),1);
    for i = 1: size(varargin{2},2)
      lHandles(i) = line([0 0], [0 0],'Parent',a1);
    end

    set(a1,'YLim',[0 length(lHandles)+1]);    
    
    setup = struct(...
      'cols',varargin{2}, ...
      'start', uint64(min(varargin{1})), ...
      'stop', uint64(max(varargin{1})), ...
      'startTime', min(varargin{1})./sampleFreq,... %Exact startTime
      'sf', sampleFreq,...
      'decimation', [], ...
      'lhandles', lHandles, ...
      'objHandles',obj, ...
      'center', [], ...
      'compression',[], ...
      'eventButtons',evButtonHandles,...
      'electrodes', [],...
      'GetDataAttr',[],...
      'eventOffsetLine',[],...
      'decimationOn', true);
    setup.GetDataAttr = getDataAttr;
    
    guidata(uihandle, setup);
    h = a1;
end

% METHODS FOR RESIZING GUI
function figResize(src,~)			
  setup = guidata(src);
	fpos = get(src,'Position');
  children = get(src,'Children');
  topPanel = findobj(children,'Tag','topP');
  botPanel = findobj(children,'Tag','botP');
  botPanel2 = findobj(children,'Tag','botP2');
  centerPanel = findobj(children,'Tag','cenP');

  tpos = get(topPanel,'position');

  bpos2 = get(botPanel2,'position');
  set(botPanel2,'Position',...
      [0.2 0.2 fpos(3)-.4 bpos2(4)])
  bpos2 = get(botPanel2,'position');

  bpos = get(botPanel,'position');
  set(botPanel,'Position',...
      [0.2 bpos2(2)+bpos2(4)+0.1 fpos(3)-.4 bpos(4)])
  bpos = get(botPanel,'position');


  cwidth = max([0.2 fpos(3)-0.4]);
  cheigth = max([0.1 fpos(4) - bpos(4)- bpos2(4)- 0.8 - tpos(4)]);
  cbottom = bpos(2)+bpos(4)+0.2;

  set(centerPanel,'Position',...
      [0.2  cbottom cwidth cheigth]);

  set(topPanel,'Position',...
      [0.2 cheigth+cbottom+0.2 cwidth tpos(4) ]);

  A1 = findobj(centerPanel,'Tag','plotWindow');
  updateRaw(A1);
  
  A2 = findobj(centerPanel,'Tag','decimation');
  set(A2,'String',sprintf('[Decimation: %i ]',setup.decimation));
  
  A3 = findobj(centerPanel,'Tag','filter');
  set(A3,'String',sprintf('[Filter: %s ]',setup.objHandles.filter));
  
end

function topPanelResize(src, ~)		
    PDFbutton = findobj(src,'Tag','pdfButton');
    pos = get(src, 'Position');
    posb = get(PDFbutton, 'Position');
    set(PDFbutton,'Position', [(pos(1)+pos(3) -posb(3)  - 0.4) posb(2) posb(3) posb(4)]);
        
    DecButton = findobj(src,'Tag','decButton');
    posb = get(DecButton, 'Position');
    set(DecButton,'Position', [(pos(1)+pos(3) -posb(3)  - 3) posb(2) posb(3) posb(4)]);


end

function botPanelResize(~, ~)		
    % Does nothing now
end

function cenPanelResize(src,~)		
    rpos = get(src,'Position');
    
    %resize listbox with properties
    listHandle = findobj(get(src,'Children'),'Tag','plotWindow');
    set(listHandle,'Position',[3 1.5 rpos(3)-3.5 rpos(4)-2.5]);
    plotpos = get(listHandle,'position');
    A2 = findobj(src,'Tag','y-scale');
    set(A2,'position',[plotpos(1) plotpos(4)+plotpos(2) 5 0.6]); 
    
    A3 = findobj(src,'Tag','decimation');
    set(A3,'position',[plotpos(1)+4 plotpos(4)+plotpos(2) 5 0.6]); 
    
    A4 = findobj(src,'Tag','filter');
    set(A4,'position',[plotpos(1)+8 plotpos(4)+plotpos(2) 10 0.6]); 
    
    
end

% GLOBAL UPDATE FUNCTIONS
function updateRaw(src, ~)			
	setup = guidata(src);

  CH = get(gcbf,'Children');
  CenP = findobj(CH,'Tag','cenP');
  axesHandle = findobj(CenP,'Tag','plotWindow');

  
	pos = get(axesHandle, 'Position');
	width = ((pos(3)-pos(1))./2.54)*72; %change to pixels.
	
	dataLength = double(setup.stop - setup.start);
  
  % Fix decimation:
  if setup.decimationOn
    setup.decimation = max([1 round((0.5*dataLength)/width)]); %2 datapoints per pixel  
  else
    setup.decimation = 1;
  end
	
	% Get Data
  aux = setup.objHandles;
  [data,time] = aux.getvalues(setup.start:setup.stop, setup.cols);
  
  % Reformat time in sec.
  time = time/1e6;
  
  % If the getdata method returns a structure, get the data property.
  if isstruct(data)
    data = double(data.data);
  else
    data = double(data);
  end
%   time = double((setup.start:setup.stop))./setup.sf;
  	
  if isempty(setup.center)
      % Only during first call
      setup.center = nanmean(data);
      setup.compression = max(max(data) - nanmean(data));
  end

  if setup.decimationOn && setup.decimation >1
      data = data(1:setup.decimation:end,:);
      time = time(1:setup.decimation:end);
  end

  for i =1: length(setup.cols)
  aux = (data(:,i)'-setup.center(i))./setup.compression + i;
    set(setup.lhandles(i),'XData',time, 'YData',aux);
  end

	set(axesHandle,'XLim',[min(time) max(time)]);	
	
%   yscaleText = sprintf('[ %3.5f %s/div ]',...
%       setup.objHandles.attr.gain*(setup.compression), ...
%       setup.objHandles.attr.units);
  yscaleText = sprintf('[ %3.5f %s/div ]',...
      (setup.compression), ...
      'uV');
    
  cp = findobj(get(gcf,'Children'),'Tag','cenP');  
    
  A2 =findobj(cp,'Tag','y-scale'); 
  set(A2,'String',yscaleText);
  
  A3 = findobj(cp,'Tag','decimation');
  set(A3,'String',sprintf('[Decimation: %i ]',setup.decimation));
  
  A4 = findobj(cp,'Tag','filter');
  set(A4,'String',sprintf('[Filter: %s ]',setup.objHandles.filter));
  
	guidata(src, setup);
end

function updateEvents(src)			
  % This function iterates over all eventButtons defined in the
  % eventButtons array in the guidata. It is easy to add new event
  % buttons to the gui just by placing them in this array and follow the
  % correct syntax requirements.
  
  setup = guidata(src);
  for i = 1: length(setup.eventButtons)

    % Only update when button is in 'on'-mode.
    ButtonUserData = get(setup.eventButtons(i),'userData');
    if ButtonUserData{1} 
      if ButtonUserData{3}
        DoubleEvent_update(setup.eventButtons(i));
        
        % Not used for IEEG-CODE, yet...
%         switch ButtonUserData{2}.type
%           case 'DoubleEvent'
%             DoubleEvent_update(setup.eventButtons(i));
%           case 'SingleEvent'
%             SingleEvent_update(setup.eventButtons(i));
%           case 'SingleMarker'
%             SingleMarker_update(setup.eventButtons(i));
%           otherwise
%             eval(sprintf('%s_update(src)',get(setup.eventButtons(i),'Tag')));
%         end
      else
        eval(sprintf('%s_update(src)',get(setup.eventButtons(i),'Tag')));
      end
    end
  end
end

% METHODS FOR GUI BUTTON CALLBACKS
function ZoomInY(src, ~)            
    setup = guidata(src);
    
    oldCompress = setup.compression;
    setup.compression = oldCompress - 0.25*oldCompress;
    
    for i = 1: length(setup.lhandles)
        aux = get(setup.lhandles(i),'YData');
        aux = aux - i;
        aux = aux * (oldCompress./setup.compression);
        set(setup.lhandles(i),'YData', aux +i);    
    end
    
    yscaleText = sprintf('[ %3.5f %s/div ]',...
      1*(setup.compression), ...
      'uV');
    cenP = findobj(get(gcf,'Children'),'Tag','cenP');   
    A2 = findobj(cenP,'Tag','y-scale');
    set(A2,'String',yscaleText);
    
    guidata(src, setup)
end

function ZoomOutY(src, ~)           
    setup = guidata(src);
    
    oldCompress = setup.compression;
    setup.compression = oldCompress + 0.25*oldCompress;
    
    for i = 1: length(setup.lhandles)
        aux = get(setup.lhandles(i),'YData');
        aux = aux - i;
        aux = aux * (oldCompress./setup.compression);
        set(setup.lhandles(i),'YData', aux +i);    
    end
    yscaleText = sprintf('[ %3.5f %s/div ]',...
      (setup.compression), ...
      'uV');
    cenP = findobj(get(gcf,'Children'),'Tag','cenP');   
    A2 = findobj(cenP,'Tag','y-scale');
    set(A2,'String',yscaleText);
    guidata(src, setup)
end

function ZoomInT(src, ~)            
    set(src, 'Enable','off');
    drawnow update
    setup = guidata(src);
    
    lData = setup.stop - setup.start + 1;
    newLength = round(lData * 0.9);
    
    setup.start = setup.start;
    setup.stop = setup.start + newLength;

    guidata(src, setup);
    
    updateRaw(src);
    updateEvents(src);
    set(src, 'Enable','on');
end

function ZoomOutT(src, ~)           

    set(src, 'Enable','off');
    drawnow update
    setup = guidata(src);
    
    lData = setup.stop - setup.start +1;
    newLength = round(lData * 1.1);
    
    setup.start = setup.start;
    setup.stop = setup.start + newLength;

    guidata(src, setup);
    
    updateRaw(src);
    updateEvents(src);
    set(src, 'Enable','on');
end

function Center(src, ~)             
    setup = guidata(src);

    for i = 1: length(setup.lhandles)
        aux = get(setup.lhandles(i),'YData') - i;
        aux = aux * setup.compression;
        aux = aux + setup.center(i);
        newMean =aux(1);
        setup.center(i) = newMean;
        set(setup.lhandles(i),'YData',(aux - newMean)./setup.compression+i);
    end

    guidata(src,setup);
    updateEvents(src);
end

function PushForwards(src, ~)       
    set(src, 'Enable','off');
    drawnow update
    setup = guidata(src);
    
    if ~isempty(setup.eventOffsetLine)
        delete(setup.eventOffsetLine);
        setup.eventOffsetLine = [];
    end
    
    ldata = setup.stop - setup.start +1;
    stripPoint = round(ldata*0.75);
    newLength = ldata - stripPoint;
    
    setup.start = setup.start + newLength;
    setup.startTime = double(setup.start)./setup.sf;
    setup.stop  = setup.stop + newLength;
    
    guidata(src, setup);
    updateRaw(src);
    updateEvents(src);
    set(src, 'Enable','on');   
end

function PushBackwards(src, ~)      
  try
    set(src, 'Enable','off');
    drawnow update
    setup = guidata(src);

    if ~isempty(setup.eventOffsetLine)
        delete(setup.eventOffsetLine);
        setup.eventOffsetLine = [];
    end

    ldata = setup.stop - setup.start +1;
    stripPoint = round(ldata*0.25);
    newLength = stripPoint;

    setup.start = setup.start - newLength;
    setup.startTime = double(setup.start)./setup.sf;
    setup.stop  = setup.stop - newLength;
        
    % Prevent negative start times.
    if setup.start < 1
      setup.stop = setup.stop - setup.start;
      setup.start = 1;
      setup.startTime = 0;
    end
    
    guidata(src, setup);
    updateRaw(src);
    updateEvents(src);
    set(src, 'Enable','on');  

  catch ME 
    set(src, 'Enable','on');
    rethrow(ME);
  end
end

function ToggleNEventButton(src,~)  
        
    setup = guidata(src);
    names = get(setup.eventButtons,'String');
    
    props = get(setup.eventButtons,'UserData');
    
    if size(props,1) == 1
      active = props{1};
      if active
        names  = {names};
      else
        names  = {};
      end
    else
      active = cellfun(@(x) x{1},props) >0;
      names = names(active);
    end
    
    if isempty(names)
        set(src,'String','-','UserData',0);
    else
        index = get(src, 'UserData') + 1;
        if index > length(names); index=1;end
        set(src, 'String', names{index}, 'UserData', index);
    end
        
end

function NextEvnt(src, ~, direction)
    
    setup = guidata(src);
    displOffsetFrac = 1/20; %offset as percentage of screen size.
    displOffset = round(displOffsetFrac * (setup.stop-setup.start));
    
    try
        set(src, 'Enable','off');
        drawnow update
        
        names = get(setup.eventButtons,'String');
        
        BotPanel = get(src,'Parent');
        TogleEvntButton = findobj(BotPanel,'Tag','EvntSelect');
        Str = get(TogleEvntButton, 'String');
                
        whichButt = find(strcmp(Str,names),1);
        curButton = setup.eventButtons(whichButt);
        
        %Xlim is threshold in time for next event
        Xlim = setup.startTime + double(displOffset) ./ setup.sf;
        
          
          usrData = get(curButton,'userData');
          
          if direction
            NextEvntIdx = find(usrData{4}./1e6 > Xlim, 1);
            if ~isempty(NextEvntIdx)
              NextEvnt = usrData{4}(NextEvntIdx)./1e6;
            else 
              NextEvnt = nan;
            end

          else
            NextEvntIdx = find(usrData{4}./1e6 < Xlim,1,'last');
            if ~isempty(NextEvntIdx)
              NextEvnt = usrData{4}(NextEvntIdx)./1e6;
            else 
              NextEvnt = nan;
            end
            
          end

        if ~isnan(NextEvnt)
            l = uint64(setup.stop-setup.start);
            
            setup.startTime = NextEvnt - double(displOffset) ./ setup.sf;
            setup.start = uint64(setup.startTime*setup.sf);

            setup.stop = setup.start + l;
                    
            if ~isempty(setup.eventOffsetLine)
              delete(setup.eventOffsetLine);
              setup.eventOffsetLine = [];
            end
            
            % Prevent negative start times.
            if setup.start < 1
              setup.stop = setup.stop - setup.start;
              setup.start = 1;
              setup.startTime = 0;
            end
            guidata(src, setup);
            
            updateRaw(src);
            
            setup = guidata(src);
            
            if direction
              if NextEvntIdx > length(usrData{4})-2 
                updateEvents(src);
              end
            else
              if usrData{4}(1) > setup.startTime*1e6
                updateEvents(src);
              end
            end
            
            CH = get(gcbf,'Children');
            CenP = findobj(CH,'Tag','cenP');
            axesHandle = findobj(CenP,'Tag','plotWindow');
            h = line([NextEvnt; NextEvnt], [0 (length(setup.lhandles)+1)], ...
              'Parent',axesHandle, 'Color','black','LineStyle','--');
            setup.eventOffsetLine = h;
            guidata(src, setup);
        
        end

        set(src,'Enable','on');
    catch ME  
        set(src,'Enable','on');
        rethrow(ME);
    end
end

function PrintPDF(~,~)              
  % Generate new figure and copy the axes. The print figure to pdf and
  % delete the figure...

  curFig = gcbf;
  cenP = findobj(get(curFig,'Children'),'Tag','cenP');
  A = findobj(get(cenP,'Children'),'Tag','plotWindow');

  topP = findobj(get(curFig,'Children'),'Tag','topP');
  T = findobj(get(topP,'Children'),'Tag','title');
  ttl = get(T,'String');

  [FileName,PathName,~] = uiputfile({'*.pdf'},'Select PDF FileName','RawViewFig.pdf');

  if ~isempty(FileName)
    aux = get(A,'Position');

    NF = figure('PaperUnits','centimeters','PaperSize',[aux(3)+4 aux(4)+4],...
        'PaperPositionMode','manual',...
        'PaperPosition',[0 0  aux(3)+5 aux(4)+5],...
        'renderer','painters',...
        'Visible','off');

    h = copyobj(A, NF);
    set(h,'Box','on');
    set(h,'Position',[2,2,aux(3),aux(4)]);
    title(h,ttl,'Interpreter','none','HorizontalAlignment','center','FontSize',12);
    print(NF,'-dpdf',fullfile(PathName,FileName));
    delete(NF);
  end
end

function EnableDec(src,~)
  setup = guidata(src);
  setup.decimationOn = ~setup.decimationOn;
  
  switch setup.decimationOn
    case false % off
      Bcolor = [0 0 0 ];
      str = 'Decimation Off';
    case true % event times
      Bcolor = [0 0.5 0];
      str = 'Decimation On';
  end

  set(src,'ForegroundColor', Bcolor,'String',str);
  
  children = get(gcf,'Children');
  centerPanel = findobj(children,'Tag','cenP');
  A1 = findobj(centerPanel,'Tag','plotWindow');
  guidata(src,setup);
  updateRaw(A1);
  
  
end

function toggleEventButton(src,~)   

  % 4 States: Off - Event Time - Event Time/value - Event Value
  setup = guidata(src);
  UD = get(src,'userData');
  UD{1} = mod(UD{1}+1,2);
  switch UD{1}
    case 0 % off
      Bcolor = [0 0 0 ];
    case 1 % event times
      Bcolor = [0 0.5 0];
      
      % Only two states are used, on/off... 
%     case 2 % event times/value
%       Bcolor = [0.5 0 0];
%     case 3 % event values
%       Bcolor = [0 0 0.5];
  end

  set(src,'userData', UD,'ForegroundColor', Bcolor);
  if UD{1}
    updateEvents(src);
  else
    try
      lineName = sprintf('%s_lines',genvarname(get(src,'Tag')));
      aux = setup.(lineName);
      delete(aux);
      setup = rmfield(setup, lineName);
    catch %#ok<CTCH>
    end
    try
      textName = sprintf('%s_text',genvarname(get(src,'Tag')));
      aux = setup.(textName);
      delete(aux);
      setup = rmfield(setup, textName);
    catch %#ok<CTCH>
    end

    guidata(src,setup);
  end
end

% METHODS FOR EVENT BUTTON CALLBACKS
function DoubleEvent_update(src, varargin)             
    
  % This methods creates timer and updates 50 annotations per callback.
  % Downloaded annotations are stored in the userdata and assumed to be
  % continuous. That is: the array contains all available annotations
  % between the first and the last downloaded annotation for all channels.
  % This allows us to reuse annotations that have been previously
  % downloaded. 
  %
  % The viewer does not automatically refresh if annotations
  % have been changed on the server.


  setup = guidata(src);

  %Get eventButtonName
  eventButtonName = genvarname(get(src,'String'));

  % Create line-objects for associated events if they do not exist.
  if ~isfield(setup, [eventButtonName '_lines'])
    setup.([eventButtonName '_lines']) = zeros(length(setup.lhandles),1);
    setup.([eventButtonName '_text']) = [];
    for iEvnt=1: length(setup.lhandles)
      setup.([eventButtonName '_lines'])(2*(iEvnt-1)+1) = line('Color','g','XData',[],'YData',[],'LineWidth',2);
      setup.([eventButtonName '_lines'])(2*(iEvnt-1)+2) = line('Color','r','XData',[],'YData',[],'LineWidth',2);
    end
  else
    aux = setup.([eventButtonName '_text']);
    if ~isempty(aux)
      delete(aux);
    end
    setup.([eventButtonName '_text']) = [];
  end

  % Update the events in the current window.
  usrData = get(src, 'userData');
  startT = 1e6 * setup.start/setup.sf;
  stopT  = 1e6 * setup.stop/setup.sf;
  channels = setup.objHandles.channels(setup.cols);
  annlayer = usrData{2};
  
  
  % Request Annotations from portal.
  REQUESTSIZE = 250;
  annotations = IEEGAnnotation.empty;
  getT = startT;
  while 1
    newAnn = annlayer.getEvents(getT, REQUESTSIZE);
    annotations = [annotations newAnn]; %#ok<AGROW>
    
    if isempty(annotations)
      break
    elseif length(newAnn) < REQUESTSIZE || annotations(end).start > stopT
      break
    end    
    getT = newAnn(end).start;
  end
  
  % Get annotations prior to timeslice;
  while 1
    % Get annotations prior to previously fetched annotations if available,
    % otherwise, try to get annotations before starttime.
    if ~isempty(annotations)
      newAnn = annlayer.getPreviousEvents(annotations(1),  REQUESTSIZE);
    else
      newAnn = annlayer.getPreviousEvents(getT,  REQUESTSIZE);
    end
    
    annotations = [newAnn annotations]; %#ok<AGROW>
    
    if isempty(annotations)
      break
    elseif annotations(1).start < startT
      break
    elseif length(newAnn) < REQUESTSIZE
      break
    end
  
  end
  
  % If this is a empty layer, return
  if isempty(annotations)
    return
  end
  
  % Populate vector with event-times in Button-UserData
  usrData{4} = [annotations.start];
  set(src, 'userData', usrData);

  % Create lines for each channel.
  for iChan = 1:length(channels)
    % Find which annotations are in current channel.
    inchannel = false(length(annotations),1);
    for iAnn = 1: length(annotations)
      inchannel(iAnn) = any(annotations(iAnn).channels == channels(iChan));
    end
    
    % Create annotation start/stop vector and render results.
    startvec = [annotations(inchannel).start]./1e6;
    stopvec = [annotations(inchannel).stop]./1e6;

    [xvals, yvals, ~] = getRasterXY(startvec, iChan, 0.5);
    set(setup.([eventButtonName '_lines'])(2*(iChan-1)+1),'XData',xvals,'YData',yvals);

    [xvals, yvals, ~] = getRasterXY(stopvec, iChan, 0.5);
    set(setup.([eventButtonName '_lines'])(2*(iChan-1)+2),'XData',xvals,'YData',yvals);
  end

  
  guidata(src,setup);

end

% GENERATING RASTER OBJECT METHOD
function [xvals,yvals,yCenter] = getRasterXY(ts,Offset,Spacing,LineLength,Start)
  %getRasterXY  get x & y values for quick raster plotting
  %   [XVALS,YVALS,YCENTER] = getRasterXY(TS,OFFSET,SPACING,LINE_LENGTH,START)
  %   uses the function YCENTER = OFFSET + SPACING*(START-1) to determine the
  %   height at which the raster line will be centered.  From their YVALS extend 
  %   from YCENTER - LINE_LENGTH/2 to YCENTER + LINE_LENGTH/2.  This format allows
  %   one to specify an intended starting OFFSET, and the START input can be used
  %   in a loop to iterate through different TS values.  TS is a vector of time events.
  %
  %   [...] = getRasterXY(TS,YCENTER,LINE_LENGTH) uses the specified YCENTER
  %   instead of that calculated by SPACING & START
  %
  if nargin == 3
      yCenter = Offset;
      LineLength = Spacing;
  elseif nargin == 5
      yCenter = Offset + Spacing*(Start-1);
  else
      error('Incorrect # of inputs')
  end

  l = length(ts);
  nans = NaN*ones(l,1);

  xvals = zeros(3*l,1);
  xvals(1:3:(3*l)) = ts;
  xvals(2:3:(3*l)) = ts;
  xvals(3:3:(3*l)) = nans;

  yvals = zeros(3*l,1);
  yvals(1:3:(3*l)) = zeros(l,1) + yCenter - (LineLength/2);
  yvals(2:3:(3*l)) = zeros(l,1) + yCenter + (LineLength/2);
  yvals(3:3:(3*l)) = nans;
end
