"""Record actual CartPole evaluation frames from an existing trained policy.
Requires: pip install gymnasium[classic-control]==0.29.1 torch numpy opencv-python
Usage: python record_trained_gameplay.py --model policy_net.pth --episodes 3
The input checkpoint must match this project's QNetwork architecture.
"""
import argparse, cv2, gymnasium as gym, torch, numpy as np
from dqn_agent import QNetwork

def main():
 p=argparse.ArgumentParser();p.add_argument('--model',default='policy_net.pth');p.add_argument('--episodes',type=int,default=3);a=p.parse_args()
 env=gym.make('CartPole-v1',render_mode='rgb_array')
 model=QNetwork(4,2);model.load_state_dict(torch.load(a.model,map_location='cpu',weights_only=True));model.eval()
 for ep in range(1,a.episodes+1):
  state,_=env.reset();writer=None;reward=0
  for t in range(500):
   with torch.no_grad(): act=int(model(torch.tensor(state,dtype=torch.float32).unsqueeze(0)).argmax(1).item())
   frame=env.render();h,w=frame.shape[:2]
   if writer is None: writer=cv2.VideoWriter(f'cartpole-evaluation-{ep:02d}.mp4',cv2.VideoWriter_fourcc(*'mp4v'),30,(w,h))
   writer.write(cv2.cvtColor(frame,cv2.COLOR_RGB2BGR))
   state,r,term,trunc,_=env.step(act);reward+=r
   if term or trunc:break
  writer.release();print(f'Episode {ep}: reward {reward}')
 env.close()
if __name__=='__main__':main()
