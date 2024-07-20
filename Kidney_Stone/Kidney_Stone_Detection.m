% ขั้นตอนที่ 1: การเข้าถึงภาพ
originalImage = imread("final 1\1-751\Stone- (275).jpg");

% แสดงภาพต้นฉบับ
figure;
imshow(originalImage);
title('Original Image');

% ขั้นตอนที่ 2: การประมวลผลภาพ
% 2.1 แปลงภาพเป็นระดับสีเทา
grayImage = rgb2gray(originalImage);

% แสดงภาพระดับสีเทา
figure;
imshow(grayImage);
title('Grayscale Image');

% 2.2 กรองภาพ (Median Filter)
filteredImage = medfilt2(grayImage);

% แสดงภาพที่ผ่านการกรองด้วย Median Filter
figure;
imshow(filteredImage);
title('Median Filtered Image');

% 2.2 การปรับปรุงภาพ (Local Power Law Transformation)
gamma = 1.5;
enhancedImage = filteredImage;

% กำหนดขนาดของพื้นที่ท้องถิ่น
regionSize = 50; % ปรับขนาดตามต้องการ

% วนลูปในภาพในพื้นที่ท้องถิ่น
for i = 1:regionSize:size(filteredImage, 1)
    for j = 1:regionSize:size(filteredImage, 2)
        % แยกพื้นที่ท้องถิ่น
        localRegion = filteredImage(i:min(i+regionSize-1, end), j:min(j+regionSize-1, end));
        
        % ใช้การปรับปรุงกฎแกมในพื้นที่ท้องถิ่น
        localEnhancedRegion = imadjust(localRegion, [], [], gamma);
        
        % วางพื้นที่ท้องถิ่นที่ปรับปรุงแล้วกลับเข้าไปในภาพ
        enhancedImage(i:min(i+regionSize-1, end), j:min(j+regionSize-1, end)) = localEnhancedRegion;
    end
end

% แสดงภาพที่ปรับปรุงแล้ว
figure;
imshow(enhancedImage);
title('Enhanced Image (Local Power Law Transformation)');

% ขั้นตอนที่ 3: การแบ่งส่วนภาพ
thresholdValue = 100;
binaryImage = enhancedImage > thresholdValue;
se = strel("disk", 1);
cleanedImage = imopen(binaryImage, se);

% แสดงภาพ binary
figure;
imshow(binaryImage);
title('Binary Image');

% แสดงภาพที่ทำการทำความสะอาดหลังจากการดำเนินการเปิด
figure;
imshow(cleanedImage);
title('Cleaned Image (After Opening)');

% ขั้นตอนที่ 4: การตรวจจับพื้นที่
stats = regionprops(cleanedImage, 'Area', 'BoundingBox');

% ลบเฉพาะนอกวัตถุที่ใหญ่ที่สุดใน regionprops
if ~isempty(stats)
    % ค้นหาดัชนีของวัตถุที่ใหญ่ที่สุด
    [~, indexOfLargest] = max([stats.Area]);

    % แยกกรอบของวัตถุที่ใหญ่ที่สุด
    largestBoundingBox = stats(indexOfLargest).BoundingBox;

    % เพิ่มความสูงในการค้นหา
    newHeight = 2 * largestBoundingBox(4); % คำนวณความสูงใหม่โดยการคูณความสูงปัจจุบันด้วย 2
    % คำนวณตำแหน่งใหม่ของ large object
    newBoundingBox = [largestBoundingBox(1), largestBoundingBox(2)-50 - largestBoundingBox(4)+10, largestBoundingBox(3)+10, newHeight];

    % กำหนดขนาดเริ่มต้นของ scale factor
    scaleFactor = 1;
    foundStones = false;

    while scaleFactor <= 5
        % คำนวณพื้นที่ด้านซ้ายและด้านขวาขึ้นอยู่กับกรอบที่ปรับปรุงแล้ว
        leftRegion = [newBoundingBox(1) - scaleFactor*newBoundingBox(3), newBoundingBox(2), scaleFactor*newBoundingBox(3), newBoundingBox(4)-13];
        rightRegion = [newBoundingBox(1) + newBoundingBox(3), newBoundingBox(2), scaleFactor*newBoundingBox(3), newBoundingBox(4)-13];

        % ให้แน่ใจว่าพื้นที่อยู่ภายในขอบเขตของภาพ
        leftRegion = max(leftRegion, 1);
        rightRegion = max(rightRegion, 1);

        % แปลงพื้นที่เป็นจำนวนเต็ม
        leftRegion = round(leftRegion);
        rightRegion = round(rightRegion);

        % แยกพื้นที่ด้านซ้ายและด้านขวาออกจากภาพที่ปรับปรุงแล้ว
        leftKidney = enhancedImage(leftRegion(2):leftRegion(2) + leftRegion(4), leftRegion(1):leftRegion(1) + leftRegion(3));
        rightKidney = enhancedImage(rightRegion(2):rightRegion(2) + rightRegion(4), rightRegion(1):rightRegion(1) + rightRegion(3));

        % ทำการแบ่งส่วนและตรวจจับพื้นที่บนไตด้านซ้ายและขวา
        leftBinaryImage = leftKidney > thresholdValue;
        rightBinaryImage = rightKidney > thresholdValue;

        leftCleanedImage = imopen(leftBinaryImage, se);
        rightCleanedImage = imopen(rightBinaryImage, se);

        % แสดงผลลัพธ์สำหรับพื้นที่ไตด้านซ้ายและขวา
        figure;
        subplot(1, 2, 1), imshow(leftCleanedImage), title(['Clean Image - Left Kidney (Scale Factor: ' num2str(scaleFactor) ')']);
        subplot(1, 2, 2), imshow(rightCleanedImage), title(['Clean Image - Right Kidney (Scale Factor: ' num2str(scaleFactor) ')']);

        % ตรวจสอบว่ามีหินไตอยู่หรือไม่โดยการตรวจสอบจำนวนพื้นที่ที่ตรวจพบ
        leftStats = regionprops(leftCleanedImage, 'Area', 'BoundingBox');
        rightStats = regionprops(rightCleanedImage, 'Area', 'BoundingBox');

        % แสดงผลลัพธ์บนภาพต้นฉบับ
        figure;
        imshow(originalImage);
        title(['Detected Regions on Original Image (Scale Factor: ' num2str(scaleFactor) ')']);

        hold on;

        % ทำเครื่องหมายพื้นที่ไตด้านซ้าย
        for i = 1:length(leftStats)
            leftStats(i).BoundingBox(1) = leftStats(i).BoundingBox(1) + leftRegion(1); % ปรับค่า x-coordinate
            leftStats(i).BoundingBox(2) = leftStats(i).BoundingBox(2) + leftRegion(2); % ปรับค่า y-coordinate
            rectangle('Position', leftStats(i).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
        end

        % ทำเครื่องหมายพื้นที่ไตด้านขวา
        for i = 1:length(rightStats)
            rightStats(i).BoundingBox(1) = rightStats(i).BoundingBox(1) + rightRegion(1); % ปรับค่า x-coordinate
            rightStats(i).BoundingBox(2) = rightStats(i).BoundingBox(2) + rightRegion(2); % ปรับค่า y-coordinate
            rectangle('Position', rightStats(i).BoundingBox, 'EdgeColor', 'b', 'LineWidth', 2);
        end

        hold off;

        % ตรวจสอบว่ามีหินไตอยู่หรือไม่โดยการตรวจสอบจำนวนพื้นที่ที่ตรวจพบ
        if ~isempty(leftStats) || ~isempty(rightStats)
            fprintf('Kidney stones detected! You should consult a doctor for further evaluation.\n');
            foundStones = true;
            break; % ออกจากลูปเมื่อพบหิน
        else
            fprintf('No kidney stones detected. Continue monitoring your health.\n');
        end

        % เพิ่ม scale factor สำหรับการวนลูปครั้งต่อไป
        scaleFactor = scaleFactor + 0.1; % ปรับการเพิ่มค่าตามต้องการ
    end
end

