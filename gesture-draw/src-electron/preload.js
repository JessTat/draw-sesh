import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('gestureApi', {
  openFolder: () => ipcRenderer.invoke('dialog:openFolder')
});
