% J Barrett
% 6-May-2022
% Project 2 Water Quality Data Analysis
% This program allows the user to look at either the chloride concentration or
% pH level of a given data set. It also creates a table containing the times of
% events crossing a limit, the duration of each event and the peak for each event.
%
% Chloride concentration limit (860 mg/L) source: https://www.epa.gov/wqc/national-recommended-water-quality-criteria-aquatic-life-criteria-table
% Fish pH limit (6.5-9) source: https://www.epa.gov/caddis-vol2/ph#:~:text=U.S.%20EPA%20water%20quality%20criteria,decreased%20growth%2C%20disease%20or%20death.

clear
clc

% Some strings used for prettier output in program
border = '----------------------------------------------------------------------------';
locations = {'Virginia Tech 24 March, 2013 - 27 March, 2013', 'Virginia Tech 12 Oct. 2014 - 15 Oct. 2014 ', 'Virginia Tech 25 Feb. 2015 - 28 Feb. 2015', 'NRCC Mall Site April 13, 2022 - 20 April, 2022'};

% Data prompt and file prompt from anonymous functions for easier maintenance
dataPrompt = @() input('What data would you like to look at?\n[1] Chloride Concentration\n[2] PH\n[3] Go Back\n');
filePrompt = @() input('Select a data set\n[1] VT 3/24/13-3/27/13\n[2] VT 10/12/14-10/15/14\n[3] VT 2/25/15-2/28/15\n[4] NR 4/13/22-4/20/22\n[5] Exit\n');
header = @(limitLabel, total) fprintf('Recorded Events Exceeding %s Limit\t\t\t# of Events: %d\n%s\nStart\t\t\t\t\tend  \t\t\t\t\tDuration\tPeak\n%s\n', limitLabel, total, border, border);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initial prompt for which file the user would like to open
selection = filePrompt();

% Run until user chooses to exit program
while selection ~= 5

  % Open and read user selected data
  data = openFile(selection);
  location = locations(selection);

  % Chloride or pH
  selection = dataPrompt();

  % Run until user wants to go back
  while selection ~= 3

      % y represents the relevant data for either Chloride or pH
      [y, limit, limitLabel] = createGraph(selection, data, location);
      n = length(y);

      % Initialise variables for event data
      event = 0;
      k = 1;
      times = datetime();

      % Find and collect times for when data crosses the limit line and the peak value for each event
      if selection == 1
        peak = 0;
        for i = 1:n
          [crossed, event, peak] = checkChloride(y(i), event, limit, peak);
          if crossed
            times(k) = data.dateTime(i);
            peaks(k) = peak;
            k = k + 1;
            peak = 0;
          end
        end
      else
        peak = 14;
        for i = 1:n
          [crossed, event, peak] = checkPH(y(i), event, limit, peak);
          if crossed
            times(k) = data.dateTime(i);
            peaks(k) = peak;
            k = k + 1;
            peak = 14;
          end
        end
      end

      n = length(times);
      totalEvents = floor(n ./ 2);

      % Print data table
      header(limitLabel, totalEvents);
      for i = 1:2:n-1
        l = between(times(i), times(i+1));
        fprintf('%s\t%s\t%s\t%0.2f\n', datestr(times(i)), datestr(times(i+1)), l, peaks(i + 1));
      end

  % reset
  selection = dataPrompt();
  close
  clc
  end
  selection = filePrompt();
end

clear
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Returns whether a specific point crosses the limit line.
% For chloride points falling above the limit line constitute an event.
function [crossed, event, peak] = checkChloride(point, event, limit, peak)
  if event && point > peak
    peak = point;
  end
  if event && point < limit
    event = 0;
    crossed = true;
  elseif event == 0 && point >= limit
    event = 1;
    crossed = true;
  else
    crossed = false;
  end
end

% Returns whether a specific point crosses the limit line.
% For pH points falling below the limit line constitute an event.
function [crossed, event, peak] = checkPH(point, event, limit, peak)
  if event && point < peak
    peak = point;
  end
  if event && point > limit
    event = 0;
    crossed = true;
  elseif event == 0 && point <= limit
    event = 1;
    crossed = true;
  else
    crossed = false;
  end
end

% Draw a graph and return either chloride or pH data as well as the limit, either
% default or user input
function [y, limit, limitLabel] = createGraph(selection, data, location)
  [labels, y] = getLabels(selection, data);
  x = data.dateTime;
  ln = plot(x,y,'lineWidth', 1.5);
  limitLine = yline(labels('limit'),'--','lineWidth', 1.5);
  limitLine.Color = [0.04 0.4 0.14];
  ln.Color = [0 0.41 0.58];

  xlabel('Time');
  ylabel(labels('yLabel'));
  title(labels('title'), location);
  legend(labels('yLabel'), labels('limitLabel'));
  drawnow
  limit = labels('limit');
  limitLabel = labels('limitLabel');
end

% Returns the relevant labels and y line data for graph
function [labels, y] = getLabels(selection, data)
  keySet = {'title', 'yLabel', 'limitLabel', 'limit'};

  selectLimit = input('Would you like to set a custom limit? [Y]/n\n', 's');

  switch selection
    case 1
      valueSet = {'Chloride Concentration','Chloride Concentration (mg/L)','EPA Recommended', 860};
      y = 0.33 * data.conductivity;
    case 2
      valueSet = {'pH Level', 'pH', 'Fish Limit', 6.5};
      y = data.pH;
  end
  labels = containers.Map(keySet, valueSet);
  if lower(selectLimit) == 'y'
      labels('limit') = input('Limit: ');
      labels('limitLabel') = 'Entered Limit';
  end
end

% Opens and reads a file then returns data
function data = openFile(selection)
  dataFiles = {'Chloride_Sonde+3-24-13+to+3-27-13.csv', 'pH_Sonde+2014_10_12_to_10_15.csv', 'Chloride_Sonde+2-25-15+to+2-28-15.csv', 'ExportedData.csv'};
  headers = {'dateTime', 'temperature', 'dissolvedOxygen', 'turbidity', 'pH', 'ORP', 'conductivity'};
  file = string(dataFiles(selection));
  data = readtable(file);
  data.Properties.VariableNames = headers;
end
