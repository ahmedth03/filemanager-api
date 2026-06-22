'use client';
import { useEffect, useRef, useState } from 'react';
import { Car, Users, Award, MapPin } from 'lucide-react';

const stats = [
  { icon: Car,   value: 500,  suffix: '+', label: 'Véhicules disponibles' },
  { icon: Users, value: 2500, suffix: '+', label: 'Clients satisfaits' },
  { icon: Award, value: 10,   suffix: ' ans', label: 'D\'expérience' },
  { icon: MapPin,value: 48,   suffix: '',  label: 'Wilayas couvertes' },
];

function Counter({ target, suffix }: { target: number; suffix: string }) {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const animated = useRef(false);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !animated.current) {
        animated.current = true;
        const start = performance.now();
        const duration = 1800;
        const step = (now: number) => {
          const t = Math.min((now - start) / duration, 1);
          const ease = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
          setCount(Math.floor(ease * target));
          if (t < 1) requestAnimationFrame(step);
          else setCount(target);
        };
        requestAnimationFrame(step);
        observer.disconnect();
      }
    }, { threshold: 0.5 });
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [target]);

  return <span ref={ref}>{count.toLocaleString()}{suffix}</span>;
}

export default function StatsSection() {
  return (
    <section className="bg-primary-500 py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
          {stats.map((s, i) => (
            <div key={i} className="text-center text-white">
              <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center mx-auto mb-4">
                <s.icon size={22} />
              </div>
              <div className="font-heading font-black text-4xl mb-2">
                <Counter target={s.value} suffix={s.suffix} />
              </div>
              <p className="text-white/80 text-sm">{s.label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
