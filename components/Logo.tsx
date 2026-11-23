import React from 'react';

interface LogoProps {
  className?: string;
  showText?: boolean;
}

const Logo: React.FC<LogoProps> = ({ className = "w-24 h-24", showText = true }) => {
  return (
    <div className="flex flex-col items-center justify-center">
      <img 
        src="/logo.png" 
        alt="PCM Logo" 
        className={`${className} object-contain`} 
      />
      {showText && (
        <div className="text-center mt-2">
          <h1 className="text-2xl font-black tracking-widest leading-none">P.C.M</h1>
          <h2 className="text-sm font-bold tracking-[0.2em] mt-1 uppercase">Wayanad</h2>
        </div>
      )}
    </div>
  );
};

export default Logo;