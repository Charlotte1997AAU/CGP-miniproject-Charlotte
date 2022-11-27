using UnityEngine;

public class PerlinNoise : MonoBehaviour
{
    public int width = 256;
    public int height = 256;

    public float scale = 20;
    public float xoffset;
    public float yoffset;
    
    void start(){
        xoffset = Random.Range(0f, 500f);
        yoffset = Random.Range(0f, 500f);
    }
    
    void Update(){
        //Reference to current render, to access the material to change the texture
        Renderer renderer = GetComponent<Renderer>();
        renderer.material.mainTexture = PerlinNoiseTexture();
    }

    Texture2D PerlinNoiseTexture (){

        Texture2D texture = new Texture2D(width, height);

        //Generate the perlin noise map. 
        //Loop through all pixels 
        for (int x = 0; x < width; x++){
            for (int y = 0; y < height; y++){
                Color color = ValueCalculator (x,y);
                texture.SetPixel(x, y, color);
            }
        }

        texture.Apply();
        return texture; 
    }

    Color ValueCalculator(int x, int y){

        //PerlinNoise repeats at whole numbers, so we turn x and y coordinate
        //into decimal place numbers, (0-1)
        float xPerlinCoord = (float)x/width * scale + xoffset;
        float yPerlinCoord = (float)y/height * scale + yoffset; 

       float value = Mathf.PerlinNoise(xPerlinCoord, yPerlinCoord);
        return new Color (value, value, value);
    }
}
