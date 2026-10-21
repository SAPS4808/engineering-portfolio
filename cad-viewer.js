import * as THREE from './three.module.js';
import { STLLoader } from './STLLoader.js';
import { OrbitControls } from './OrbitControls.js';
export function mountCAD(){
 const host=document.getElementById('cad-canvas'),select=document.getElementById('cad-model'),status=document.getElementById('cad-status');
 if(!host)return;
 let renderer,mesh,alive=true,request=0;
 try{renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});}catch{status.textContent='3D preview unavailable. Download the STL to inspect the model.';return;}
 renderer.setPixelRatio(Math.min(devicePixelRatio,2));host.appendChild(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(38,1,.01,1000);
 const controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=false;
 scene.add(new THREE.HemisphereLight(0xffffff,0x7a7d70,2.5));
 const key=new THREE.DirectionalLight(0xffffff,3);key.position.set(4,8,6);scene.add(key);
 const fill=new THREE.DirectionalLight(0xffffff,1.4);fill.position.set(-4,2,-4);scene.add(fill);
 const render=()=>{if(alive)renderer.render(scene,camera);};
 function reset(){camera.position.set(2.4,1.8,2.8);controls.target.set(0,0,0);controls.update();render();}
 const resize=new ResizeObserver(()=>{if(!alive)return;const w=host.clientWidth,h=host.clientHeight;renderer.setSize(w,h);camera.aspect=w/h;camera.updateProjectionMatrix();render();});resize.observe(host);
 controls.addEventListener('change',render);
 async function load(){const token=++request;status.hidden=false;status.textContent='Loading model…';document.getElementById('cad-download').href=select.value;
 try{const geometry=await new STLLoader().loadAsync(select.value);if(!alive||token!==request){geometry.dispose();return;}
 geometry.computeBoundingBox();const size=new THREE.Vector3();geometry.boundingBox.getSize(size);geometry.center();geometry.scale(2/Math.max(size.x,size.y,size.z),2/Math.max(size.x,size.y,size.z),2/Math.max(size.x,size.y,size.z));geometry.computeVertexNormals();
 if(mesh){scene.remove(mesh);mesh.geometry.dispose();mesh.material.dispose();}
 mesh=new THREE.Mesh(geometry,new THREE.MeshStandardMaterial({color:0x9ba6ad,metalness:.22,roughness:.42,side:THREE.DoubleSide}));scene.add(mesh);status.hidden=true;reset();
 }catch{if(alive&&token===request){status.hidden=false;status.textContent='Model could not load. Download the STL to inspect it.';}}}
 select.addEventListener('change',load);document.getElementById('cad-reset').addEventListener('click',reset);load();
 window.disposeCAD=()=>{alive=false;request++;resize.disconnect();controls.dispose();if(mesh){mesh.geometry.dispose();mesh.material.dispose();}renderer.dispose();};
}
