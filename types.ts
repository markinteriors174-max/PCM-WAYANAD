export interface User {
  phoneNumber: string;
  isLoggedIn: boolean;
}

export enum AppTab {
  HOME = 'HOME',
  GALLERY = 'GALLERY',
  VISUALIZER = 'VISUALIZER',
  ASSISTANT = 'ASSISTANT'
}

export interface CeilingDesign {
  id: string;
  name: string;
  imageUrl: string; // URL for the overlay texture
  thumbnail: string;
}
