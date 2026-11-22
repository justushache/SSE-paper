

range = (0:1023);
data = sin(range/100)+sin(range/10)+sin(range/200)+sin(range/5)+sin(range);

result = zeros(length(data),1);

close all
figure(1)
clf()
hold on
%im plotting the matlab fft vs my fft, to compare the results
%my fft is offset by 50, so the lines arent on top of another
subplot(2,1,1)
% matlab FFT
plot(range, abs(fft(data)))
subplot(2,1,2)
%my FFT
plot(range, abs(jfft(data,length(data))));


function retarr=jfft(arraydata,len)
    % needs to have a length of power of 2

    %after going through all the stages of the  
    x = (0:len-1);
    addrestranslation = bitrevorder(x);
    arraydata2 = arraydata;
    for index = (1:len)
        newindex = addrestranslation(index)+1; 
        arraydata(newindex)= arraydata2(index);
    end
    stagepow = 1;
    depth = log2(len); % in hardware this could be easily done by choosing position of the set bit in len
    for stage = (1:depth)
        
        stagepow = stagepow*2; % in hardware this is just previous stagepow * 2
        delta_omega = exp(-2 * pi *1i/stagepow);

        for k = (0:stagepow:len-1)
            omega = 1; % prevent, that omega drifts of due to calculation errors;
            for j = (k : k+stagepow/2 -1)
                % TODO: write this so that imaginary number operations can
                % be done with normal hardware
                t = omega*arraydata(j + stagepow/2+1);
                u = arraydata(j+1);
                arraydata(j+1) =  u + t;
                arraydata(j + stagepow/2+1) = u - t;
                omega = omega * delta_omega;
            end
        end
    end

    retarr = arraydata;
    return;
end
