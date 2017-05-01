% Criado por Arthur Marques Medeiros

function rawToJPEG(rawImageSource)
    warning off
    tic
    t = Tiff(rawImageSource, 'r');
    offsets = getTag(t,'SubIFD');
    setSubDirectory(t,offsets(1));
    rawArray = read(t);
    close(t);
    dArray = bilinearDemosaicking(rawArray, 'RGGB');
    wArray = whiteBalance(dArray, 1);
    % imtool(uint8(wArray)) pode ser usado para preview
    lArray = gammaCorrection(wArray);
    % imtool(uint8(lArray)) pode ser usado para preview
    imwrite(uint8(lArray), 'result.jpeg');
    toc
end

function nArray = gammaCorrection(oArray)
    sizeA = size(oArray);
    gamma = 2.2;
    nArray = zeros(sizeA(1), sizeA(2), 3);
    for i = 1 : sizeA(1)
       for j = 1: sizeA(2)
           nArray(i,j,1) = (oArray(i,j,1)/255)^(1/gamma) * 255;
           nArray(i,j,2) = (oArray(i,j,2)/255)^(1/gamma) * 255;
           nArray(i,j,3) = (oArray(i,j,3)/255)^(1/gamma) * 255;
       end
    end
    
end

function bArray = whiteBalance(nArray, type)
    maxRed = 0;
    maxGreen = 0;
    maxBlue = 0;
    sizeA = size(nArray);
    bArray = zeros(sizeA(1), sizeA(2), 3);
    for i = 1 : sizeA(1)
        for j = 1: sizeA(2)
            if maxRed < nArray(i,j,1)
                maxRed = nArray(i,j,1);
            end
            if maxGreen < nArray(i,j,2)
                maxGreen = nArray(i,j,2);
            end
            if maxBlue < nArray(i,j,3)
                maxBlue = nArray(i,j,3);
            end
        end
    end
    for i = 1 : sizeA(1)
        for j = 1: sizeA(2)
            bArray(i,j,1) = nArray(i,j,1)*255/maxRed;
            bArray(i,j,2) = nArray(i,j,2)*255/maxGreen;
            bArray(i,j,3) = nArray(i,j,3)*255/maxBlue;
        end
    end
    
    if type == 0 % Gray World Assumption
        
        somaRed = 0;
        somaGreen = 0;
        somaBlue = 0;
        for i = 1 : sizeA(1)
            for j = 1: sizeA(2)
                somaRed = somaRed + bArray(i,j,1);
                somaGreen = somaGreen + bArray(i,j,2);
                somaBlue = somaBlue + bArray(i,j,3);
            end
        end
        numPixels = sizeA(1) * sizeA(2);
        
        mediaRed = somaRed / numPixels;
        mediaGreen = somaGreen / numPixels;
        mediaBlue = somaBlue / numPixels;
        
        alpha = mediaGreen/mediaRed;
        beta = mediaGreen/mediaBlue;
        
        for i = 1 : sizeA(1)
            for j = 1: sizeA(2)
                bArray(i,j,1) = alpha * bArray(i,j,1);
                bArray(i,j,2) = bArray(i,j,2);
                bArray(i,j,3) = beta * bArray(i,j,3);
            end
        end
        
    end
    
    if type == 1 % White Patch Assumption
        
        alpha = maxGreen/maxRed;
        beta = maxGreen/maxBlue;
        
        for i = 1 : sizeA(1)
            for j = 1: sizeA(2)
                bArray(i,j,1) = alpha * bArray(i,j,1);
                bArray(i,j,2) = bArray(i,j,2);
                bArray(i,j,3) = beta * bArray(i,j,3);
            end
        end
        
    end
    
end


function cArray = bilinearDemosaicking(rArray, name)
    cfa = colorFilterArray(name);
    sizeA = size(rArray);
    
    cArray = zeros(sizeA(1), sizeA(2), 3);
    
    for i = 1 : sizeA(1)
        for j = 1: sizeA(2)
            cArray(i,j,1) = solvePixelColor(rArray, i, j, cfa, sizeA, 1);
            cArray(i,j,2) = solvePixelColor(rArray, i, j, cfa, sizeA, 2);
            cArray(i,j,3) = solvePixelColor(rArray, i, j, cfa, sizeA, 3);
        end
    end
end

function v = solvePixelColor (rArray, i, j, cfa, size, colorIndex)

    iCfa = mod(i-1,2)+1;
    jCfa = mod(j-1,2)+1;
    if cfa(iCfa,jCfa,colorIndex) == 1
            v = rArray(i,j);
        else
            count = 0;
            value = 0;
            for n = -1 : +1
                for m = -1 : +1           
                    
                    if (iCfa+n) == 0
                        truen = 2;
                    elseif (iCfa+n) == 3
                        truen = 1;
                    else
                        truen = iCfa+n;
                    end
                                
                    
                    if (jCfa+m) == 0
                        truem = 2;
                    elseif (jCfa+m) == 3
                        truem = 1;
                    else
                        truem = jCfa+m;
                    end
                    
                    
                    if (cfa(truen, truem, colorIndex) == 1)
                        if (and(i+n>0,j+m>0))
                            if (and(i+n<=size(1), j+m<=size(2)))
                                count = count + 1;
                                value = value + rArray(i+n,j+m);
                            end
                        end
                    end
                end
            end
            
            v = value/count;
    end
    
end
   
function cfa = colorFilterArray(name)
% Variações do Bayer Filter
    if name == 'RGGB'
        cfa(:,:,1) = [1 0; 0 0];
        cfa(:,:,2) = [0 1; 1 0];
        cfa(:,:,3) = [0 0; 0 1];
        
    elseif name == 'GRBG'
        cfa(:,:,1) = [0 1; 0 0];
        cfa(:,:,2) = [1 0; 0 1];
        cfa(:,:,3) = [0 0; 1 0];
    
    elseif name == 'BGGR'
        cfa(:,:,1) = [0 0; 0 1];
        cfa(:,:,2) = [0 1; 1 0];
        cfa(:,:,3) = [1 0; 0 0];
    end
end