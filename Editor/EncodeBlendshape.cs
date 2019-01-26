using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

public class EncodeBlendshape : EditorWindow
{
	Mesh targetMesh;
	string blendShapeName;

	[MenuItem("RedMage/Collision Shader/Encode Blendshape")]
	static void Init() 
	{
		EncodeBlendshape window = (EncodeBlendshape) EditorWindow.GetWindow(typeof(EncodeBlendshape));
		window.Show();
	}
	
	void OnGUI() 
	{
		targetMesh = EditorGUILayout.ObjectField("Mesh", targetMesh, typeof(Mesh), true) as Mesh;
		blendShapeName = EditorGUILayout.TextField("Blendshape Name", blendShapeName);
		
		if (GUILayout.Button("Encode Blendshape")) 
		{
			int vertexCount = targetMesh.vertexCount;
			
			// figure out what texture size to use.
			// we need 3 values per vertex, (xyz), and we want the texture to be a power of two.
			// basically, the conditions (imageSize == pow(2,k)) and (imageSize * imageSize >= vertexCount * 3) need to be true
			// so if you do some math, we'll be rounding sqrt(vertexCount * 3) up to the nearest power of two.
			// which is what this does.
			int imageSize = 1 << (FloorLogBase2((int) (Mathf.Sqrt(vertexCount * 3) + .5) - 1) + 1);
			Texture2D img = new Texture2D(imageSize, imageSize);
			
			
			int shapeIndex = targetMesh.GetBlendShapeIndex(blendShapeName);
			Vector3[] deltaVertices = new Vector3[vertexCount];
			targetMesh.GetBlendShapeFrameVertices(shapeIndex, 0, deltaVertices, null, null);
			
			// initial scan to determine compression factors
			Vector3 lowest = new Vector3(float.PositiveInfinity, float.PositiveInfinity, float.PositiveInfinity);
			Vector3 highest = new Vector3(float.NegativeInfinity, float.NegativeInfinity, float.NegativeInfinity);
			foreach (Vector3 v in deltaVertices)
			{
				lowest.x = Mathf.Min(lowest.x, v.x);
				lowest.y = Mathf.Min(lowest.y, v.y);
				lowest.z = Mathf.Min(lowest.z, v.z);
				highest.x = Mathf.Max(highest.x, v.x);
				highest.y = Mathf.Max(highest.y, v.y);
				highest.z = Mathf.Max(highest.z, v.z);
			}
			
			// our compression factors to compress/decompress from the [0,1] range of color encoding.
			Vector3 offset = new Vector3(-lowest.x, -lowest.y, -lowest.z);
			Vector3 scale = new Vector3(highest.x - lowest.x, highest.y - lowest.y, highest.z - lowest.z);
			// avoid issues with division by 0
			if (Mathf.Abs(scale.x) < 1) scale = new Vector3(1, scale.y, scale.z);
			if (Mathf.Abs(scale.y) < 1) scale = new Vector3(scale.x, 1, scale.z);
			if (Mathf.Abs(scale.z) < 1) scale = new Vector3(scale.x, scale.y, 1);

			for (int i = 0; i < vertexCount; ++i)
			{
				Vector3 v = deltaVertices[i];
				float x = (v.x + offset.x) / scale.x;
				float y = (v.y + offset.y) / scale.y;
				float z = (v.z + offset.z) / scale.z;
				img.SetPixel((i * 3 + 0) % imageSize, (i * 3 + 0) / imageSize, EncodeFloatRGBA(x * 0.5f));
				img.SetPixel((i * 3 + 1) % imageSize, (i * 3 + 1) / imageSize, EncodeFloatRGBA(y * 0.5f));
				img.SetPixel((i * 3 + 2) % imageSize, (i * 3 + 2) / imageSize, EncodeFloatRGBA(z * 0.5f));
			}

			// Save Assets with needed properties.
			var saveTo = EditorUtility.SaveFilePanelInProject("Save lookup texture", "", "", "");
			var imagePath = saveTo + ".png";
			
			File.WriteAllBytes(imagePath, img.EncodeToPNG());
			AssetDatabase.ImportAsset(imagePath);
			AssetDatabase.SaveAssets();
			
			TextureImporter importer = (TextureImporter) TextureImporter.GetAtPath(imagePath);
			importer.wrapMode = TextureWrapMode.Clamp;
			importer.mipmapEnabled = false;
			importer.maxTextureSize = imageSize;
			importer.sRGBTexture = false;
			importer.filterMode = FilterMode.Point;
			importer.textureCompression = TextureImporterCompression.Uncompressed;
			importer.SaveAndReimport();
			
			Material material = new Material(Shader.Find("RedMage/Collision"));
			material.SetTexture("_BlendshapeLookupMap", (Texture2D) AssetDatabase.LoadAssetAtPath(imagePath, typeof(Texture2D)));
			material.SetVector("_CompressionFactor", new Vector4(scale.x, scale.y, scale.z, 0));
			material.SetVector("_CompressionOffset", new Vector4(offset.x, offset.y, offset.z, 0));
			material.SetInt("_MapSize", imageSize);
			AssetDatabase.CreateAsset(material, saveTo + ".mat");
			AssetDatabase.SaveAssets();
		}
	}
	
	// you can find this on StackOverflow
	private static Color EncodeFloatRGBA(float v)
	{
		var vi = (uint)(v * (256.0f * 256.0f * 256.0f * 256.0f));
		var ex = (int)(vi / (256 * 256 * 256) % 256);
		var ey = (int)((vi / (256 * 256)) % 256);
		var ez = (int)((vi / (256)) % 256);
		var ew = (int)(vi % 256);
		return new Color(ex / 255.0f, ey / 255.0f, ez / 255.0f, ew / 255.0f);
	}

	// you can also find this on StackOverflow
	private static readonly int[] MultiplyDeBrujinBitPosition = new int[32]
	{
		0, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18, 22, 25, 3, 30,
		8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31
	};
	private static int FloorLogBase2(int v)
	{
		v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16;
		return MultiplyDeBrujinBitPosition[(uint)(v * 0x07C4ACDDU) >> 27];
	}
}
