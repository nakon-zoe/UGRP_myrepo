import easydict
from tf_pose.estimator import TfPoseEstimator
from tf_pose.networks import get_graph_path, model_wh
import os
import tensorflow as tf
from PIL import ImageFont, ImageDraw, Image
import logging
import math
import slidingwindow as sw
import cv2
import numpy as np
import time
from tf_pose import common
from tf_pose.common import CocoPart
from tf_pose.tensblur.smoother import Smoother
import glob
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import load_model



# CNN 모델 load
model = load_model("CNN_best_model_98_tf1.h5")




# TF-Pose 객체 생성
e = TfPoseEstimator(get_graph_path('mobilenet_thin'), target_size=(480, 640))

count = 0
cap = cv2.VideoCapture(1)
categories = ['pedestrian', 'sitter', 'taxier']

while True:
    ret, image = cap.read()
    img_x_max, img_y_max, _ = image.shape
    people_bbox = dict()

    if not ret:
        break

    # Skeleton 그리기 with Background
    humans = e.inference(image, upsample_size=4.0)
    image, detected_humans = TfPoseEstimator.draw_humans(image, humans, imgcopy=False)

    for coors in detected_humans:
        # 가로 200pixel 세로 300pixel 이하 제외
        #         if w < 100 and h < 200: continue
        cv2.rectangle(image, (coors[0], coors[1]), (coors[2], coors[3]), (0, 0, 255), 3)

        # image resizing and reshape (Preprocessing)
        input_image = image[int(coors[1]):int(coors[3]), int(coors[0]):int(coors[2])]

        img = Image.fromarray(input_image, "RGB")
        img = img.convert("RGB")
        img = img.resize((256, 256))
        data = np.asarray(img)

        X = np.array(data)
        X = X.astype("float") / 256
        X = X.reshape(-1, 256, 256, 3)

        # model prediction
        result = [np.argmax(value) for value in model.predict(X)]
        result = categories[result[0]]
        people_bbox[(coors[0], coors[1], coors[2], coors[3])] = result

    # esc 누르면 종료
    if cv2.waitKey(10) == 27:
        break
    print('%d.jpg done' % count)
    count += 1

    # Class name print
    for coors in people_bbox:
        gesture = people_bbox[(coors[0], coors[1], coors[2], coors[3])]
        x = coors[0]
        y = coors[1]

        if x > img_x_max - 10:
            x = img_x_max - 10

        if y > img_y_max - 10:
            y = img_y_max - 10

        cv2.putText(image, gesture, (x, y), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2, cv2.LINE_AA)
    cv2.imshow("Gesture_Recognition", image)

# 윈도우 종료
cap.release()
cv2.destroyWindow('Gesture_Recognition')