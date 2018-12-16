import os
import sys
import random
import math
import numpy as np
import skimage.io
import csv

import matplotlib
import matplotlib.pyplot as plt

MRCNN_DIR = os.path.abspath("../mask_rcnn")
ROOT_DIR = os.path.abspath("../")

# Import Mask RCNN
sys.path.append(MRCNN_DIR)  # To find local version of the library
from mrcnn import utils
import mrcnn.model as modellib

from mrcnn import visualize

# Import COCO config
sys.path.append(os.path.join(MRCNN_DIR, "samples/coco/"))  # To find local version
import coco


class InferenceConfig(coco.CocoConfig):
    # Set batch size to 1 since we'll be running inference on
    # one image at a time. Batch size = GPU_COUNT * IMAGES_PER_GPU
    GPU_COUNT = 1
    IMAGES_PER_GPU = 1


def read_class_names(fpath):
    with open(fpath) as csv_file:
        reader = csv.reader(csv_file, delimiter=",")
        return [row[0] for row in reader]


class MaskGenerator:
    def __init__(self):
        # Directory to save logs and trained model
        self.MODEL_DIR = os.path.join(MRCNN_DIR, "logs")

        # Local path to trained weights file
        self.COCO_MODEL_PATH = os.path.join(MRCNN_DIR, "mask_rcnn_coco.h5")
        # Download COCO trained weights from Releases if needed
        if not os.path.exists(self.COCO_MODEL_PATH):
            utils.download_trained_weights(self.COCO_MODEL_PATH)

        # Directory of images to run detection on
        self.IMAGE_DIR = os.path.abspath("../images")
        self.config = InferenceConfig()
        self.class_names = read_class_names(
            os.path.join(ROOT_DIR, "assets/class_names.csv")
        )
        self.model = modellib.MaskRCNN(
            mode="inference", model_dir=self.MODEL_DIR, config=self.config
        )
        self.model.load_weights(self.COCO_MODEL_PATH, by_name=True)

    def computeMasks(self, img):
        results = self.model.detect([img], verbose=1)
        return results[0]["masks"]
