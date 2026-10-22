import * as THREE from './three.module.js';
import { STLLoader } from './STLLoader.js';
import { OrbitControls } from './OrbitControls.js';
export function mountCAD(){
 const host=document.getElementById('cad-canvas'),select=document.getElementById('cad-model'),status=document.getElementById('cad-status'),referenceToggle=document.getElementById('cad-reference');
 if(!host)return;
 let renderer,model,alive=true,request=0;
 try{renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});}catch{status.textContent='3D preview unavailable. Download the STL to inspect the model.';return;}
 renderer.setPixelRatio(Math.min(devicePixelRatio,2));host.appendChild(renderer.domElement);
 const scene=new THREE.Scene(),camera=new THREE.PerspectiveCamera(38,1,.01,1000);
 const controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=false;
 scene.add(new THREE.HemisphereLight(0xffffff,0x7a7d70,2.5));
 const key=new THREE.DirectionalLight(0xffffff,2.6);key.position.set(4,8,6);scene.add(key);
 const fill=new THREE.DirectionalLight(0xffffff,1.4);fill.position.set(-4,2,-4);scene.add(fill);
 const render=()=>{if(alive)renderer.render(scene,camera);};
 function reset(){const a=model?.userData.assembly;camera.position.set(...(a?[1.7,1.65,2.1]:[2.25,2.2,2.8]));camera.position.multiplyScalar(Math.max(1,1.4/camera.aspect));controls.target.set(0,0,0);controls.update();render();}
 const resize=new ResizeObserver(()=>{if(!alive)return;renderer.setSize(host.clientWidth,host.clientHeight);camera.aspect=host.clientWidth/host.clientHeight;camera.updateProjectionMatrix();render();});resize.observe(host);
 controls.addEventListener('change',render);
 function dispose(object){object?.traverse(o=>{o.geometry?.dispose();if(Array.isArray(o.material))o.material.forEach(m=>m.dispose());else o.material?.dispose();});}
 function referenceVisibility(){if(model)model.traverse(o=>{if(o.userData.reconstructed)o.visible=referenceToggle.checked;});render();}
 async function load(){const token=++request;status.hidden=false;status.textContent='Loading model…';const isAssembly=select.value.split('?')[0].endsWith('.json');document.getElementById('cad-download').href=select.value.replace(/\.json(?:\?.*)?$/,'.stl');referenceToggle.closest('label').hidden=!isAssembly;
 try{
 let object;
 if(isAssembly)object=await new THREE.ObjectLoader().loadAsync(select.value);
 else{const geometry=await new STLLoader().loadAsync(select.value);geometry.computeVertexNormals();object=new THREE.Mesh(geometry,new THREE.MeshStandardMaterial({color:0x9ba6ad,metalness:.22,roughness:.42,side:THREE.DoubleSide}));}
 if(!alive||token!==request){dispose(object);return;}referenceToggle.closest('label').hidden=!isAssembly||!!object.userData.visualOnly;
 const bounds=new THREE.Box3().setFromObject(object),size=bounds.getSize(new THREE.Vector3()),center=bounds.getCenter(new THREE.Vector3());
 const wrapper=new THREE.Group();wrapper.userData.assembly=isAssembly;object.position.sub(center);wrapper.add(object);wrapper.scale.setScalar(2/Math.max(size.x,size.y,size.z));
 if(model){scene.remove(model);dispose(model);}model=wrapper;scene.add(model);referenceVisibility();status.hidden=true;reset();
 }catch{if(alive&&token===request){status.hidden=false;status.textContent='Model could not load. Download the STL to inspect it.';}}}
 select.addEventListener('change',load);referenceToggle.addEventListener('change',referenceVisibility);document.getElementById('cad-reset').addEventListener('click',reset);load();
 window.disposeCAD=()=>{alive=false;request++;resize.disconnect();controls.dispose();dispose(model);renderer.dispose();};
}
