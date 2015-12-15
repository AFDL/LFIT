function progress( m, n )
% When called within a loop, displays the progress with time remaining.


global progress_t0 progress_lasttoc

if m==0
    fprintf( '\n  Time remaining:' );
    fprintf( '          unknown.' );
    progress_t0 = tic;
    progress_lasttoc = 0;
    
elseif m==n
    for k=1:18, fprintf('\b'); end
    fprintf( '         complete.\n' );
    clear global progress_t0 progress_lasttoc
    
else
    timeElapsed     = toc(progress_t0);
    timeRemaining   = timeElapsed*(n-m)/m;
    
    if timeElapsed-progress_lasttoc<1
        % Don't update more than once per second
    else
        progress_lasttoc = timeElapsed;

        dd = floor( timeRemaining/86400 );
        hh = floor( timeRemaining/3600 - 24*dd );
        mm = floor( timeRemaining/60 - 60*hh - 1440*dd );
        ss = floor( timeRemaining - 60*mm - 3600*hh - 86400*dd );

        for k=1:18, fprintf('\b'); end

        if dd>=1
            fprintf( ' %3dd %2dh %2dm %2ds.', dd,hh,mm,ss );
        elseif hh>=1
            fprintf( '      %2dh %2dm %2ds.', hh,mm,ss );
        elseif mm>=1
            fprintf( '          %2dm %2ds.', mm,ss );
        else
            fprintf( '              %2ds.', ss );
        end
    end

end%if
