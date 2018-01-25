package netlogo;

import java.io.File;
import java.util.Random;

import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.Rect;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.highgui.Highgui;
import org.opencv.imgproc.Imgproc;

public class DatasetPreparation {
	
	// Rutas a los directorios que contienen las imágenes de entrada y salida
	public static final String DIR_IN_CEDA = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPG/ceda";
	public static final String DIR_OUT_CEDA = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPGOut/ceda";
	
	public static final String DIR_IN_PROHIBIDO = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPG/prohibido";
	public static final String DIR_OUT_PROHIBIDO = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPGOut/prohibido";
	
	public static final String DIR_IN_STOP = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPG/stop";
	public static final String DIR_OUT_STOP = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPGOut/stop";
	
	public static final String DIR_IN_LIMITE = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPG/limite";
	public static final String DIR_OUT_LIMITE = "D:/BelgiumTS Dataset/TSImages/Classification/TestingJPGOut/limite";
	
	public static final String DIR_IN_NEG = "D:/BelgiumTS Dataset/NonTSImages/TrainingBGJPG";
	public static final String DIR_OUT_NEG = "D:/BelgiumTS Dataset/NonTSImages/TrainingBGJPGOut";


	public static void main(String[] args) {
		// Cargar OpenCV
		System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

		GenerateHSVPositiveDataset(DIR_IN_CEDA,DIR_OUT_CEDA);
		GenerateHSVPositiveDataset(DIR_IN_PROHIBIDO,DIR_OUT_PROHIBIDO);
		GenerateHSVPositiveDataset(DIR_IN_STOP,DIR_OUT_STOP);
		GenerateHSVPositiveDataset(DIR_IN_LIMITE,DIR_OUT_LIMITE);
		GenerateHSVNegativeDataset();
	}
	
	/*
	 * Función para generar las imágenes positivas (señales de tráfico)
	 * */
	private static void GenerateHSVPositiveDataset(String inDirName, String outDirName){
		// Recorrer directorio
		File dirIn = new File (inDirName);
		if(dirIn.exists() || dirIn.isDirectory()){
			Mat imageHSV = new Mat();
			Mat imageHSVRedLower = new Mat();
			Mat imageHSVRedUpper = new Mat();
			Mat imageHSVRed = new Mat();
			for(File file : dirIn.listFiles()){
				// Cargar imagen de entrada. OpenCV usa BGR, no RGB
				Mat imageBGR = Highgui.imread(file.getAbsolutePath(), Highgui.CV_LOAD_IMAGE_COLOR);
				// Convertir imagen a espacio de color HSV
				Imgproc.cvtColor(imageBGR, imageHSV, Imgproc.COLOR_BGR2HSV);
				// Redimensionarla a 40x40 píxeles
				Imgproc.resize(imageHSV, imageHSV, new Size(40,40));
				// Crear dos imágenes con los dos rangos de rojo del espectro HSV
				Core.inRange(imageHSV, new Scalar(0, 100, 100), new Scalar(15, 255, 255), imageHSVRedLower);
				Core.inRange(imageHSV, new Scalar(160, 100, 100), new Scalar(180, 255, 255), imageHSVRedUpper);
				// Unir las dos imágenes
				Core.addWeighted(imageHSVRedLower, 1.0, imageHSVRedUpper, 1.0, 0.0, imageHSVRed);
				// Invertir el color de los píxeles: los blancos pasan a ser negros y viceversa
				Imgproc.threshold(imageHSVRed, imageHSVRed, 0, 255, Imgproc.THRESH_BINARY_INV);
				// Guardar imagen procesada
				Highgui.imwrite(outDirName + File.separator + file.getName(), imageHSVRed);
				// Liberar memoria
				imageBGR.release();
				imageHSV.release();
				imageHSVRedLower.release();
				imageHSVRedUpper.release();
				imageHSVRed.release();
			}
		}
	}
	
	
	/*
	 * Función para generar las imágenes negativas (fondo)
	 * */
	private static void GenerateHSVNegativeDataset(){
		File dirIn = new File (DIR_IN_NEG);
		Random random = new Random();
		if(dirIn.exists() || dirIn.isDirectory()){
			Mat imageBGR = new Mat();
			Mat croppedBGR = new Mat();
			Mat imageHSV = new Mat();
			Mat imageHSVRedLower = new Mat();
			Mat imageHSVRedUpper = new Mat();
			Mat imageHSVRed = new Mat();
			Rect roi = new Rect();
			int randomSize;
			int randomX;
			int randomY;
			for(File file : dirIn.listFiles()){
				// Cargar imagen de fondo
				imageBGR = Highgui.imread(file.getAbsolutePath(), Highgui.CV_LOAD_IMAGE_COLOR);
				// Redimensionar para que el procesamiento tarde menos (la imagen original es muy pesada)
				Imgproc.resize(imageBGR, imageBGR, new Size(1024,768));
				// Cambiar imagen a espacio de colores HSV
				Imgproc.cvtColor(imageBGR, imageHSV, Imgproc.COLOR_BGR2HSV);
				// Recortar 10 imágenes de 40x40 píxeles de forma aleatoria
				for (int j = 0; j < 10; j++) {
					// Número aleatorio entre [40,100]
					randomSize =  random.nextInt((100 - 40) + 1) + 40;
					// Número aleatorio entre [num cols,randomSize]
					randomX = random.nextInt(imageBGR.cols() - randomSize + 1);
					// Número aleatorio entre [num rows,randomSize]
					randomY = random.nextInt(imageBGR.rows() - randomSize + 1);
					// Crear área de recorte
					roi = new Rect(randomX, randomY, randomSize, randomSize);
					// Recortar imagen
					croppedBGR = new Mat(imageBGR, roi);
					// Redimensionar nuevamente aunque el tamaño de la imagen recortada debe ser ya 40x40
					Imgproc.resize(croppedBGR, croppedBGR, new Size(40, 40));
					// Crear dos imágenes con los dos rangos de rojo del espectro HSV
					Core.inRange(imageHSV, new Scalar(0, 100, 100), new Scalar(15, 255, 255), imageHSVRedLower);
					Core.inRange(imageHSV, new Scalar(160, 100, 100), new Scalar(180, 255, 255), imageHSVRedUpper);
					// Unir las dos imágenes
					Core.addWeighted(imageHSVRedLower, 1.0, imageHSVRedUpper, 1.0, 0.0, imageHSVRed);
					// Invertir el color de los píxeles: los blancos pasan a ser negros y viceversa
					Imgproc.threshold(imageHSVRed, imageHSVRed, 0, 255, Imgproc.THRESH_BINARY_INV);
					// Guardar imagen procesada
					Highgui.imwrite(DIR_OUT_NEG + File.separator + file.getName().substring(0,
							file.getName().lastIndexOf("."))
							+ j + ".jpg", imageHSVRed);
					// Liberar memoria
					croppedBGR.release();
					imageHSV.release();
					imageHSVRedLower.release();
					imageHSVRedUpper.release();
					imageHSVRed.release();
				}
				imageBGR.release();
			}
		}
	}

}
