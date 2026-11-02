"""
evaluate.py – Load a trained DQN and run evaluation episodes.
Usage:
    python evaluate.py --model policy_net.pth --episodes 10 --render
"""

import argparse
import gymnasium as gym
import numpy as np
import torch

from dqn_agent import QNetwork


def evaluate(model_path: str, num_episodes: int = 10, render: bool = False):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    env = gym.make("CartPole-v1", render_mode="human" if render else None)
    state_dim  = env.observation_space.shape[0]
    action_dim = env.action_space.n

    # Load trained weights
    net = QNetwork(state_dim, action_dim).to(device)
    net.load_state_dict(torch.load(model_path, map_location=device))
    net.eval()

    rewards = []
    for ep in range(1, num_episodes + 1):
        state, _     = env.reset()
        total_reward = 0

        for _ in range(500):
            state_t  = torch.tensor(state, dtype=torch.float32).unsqueeze(0).to(device)
            with torch.no_grad():
                action = int(net(state_t).argmax(dim=1).item())

            state, reward, terminated, truncated, _ = env.step(action)
            total_reward += reward
            if terminated or truncated:
                break

        rewards.append(total_reward)
        print(f"  Episode {ep:>3d}: reward = {total_reward:.1f}")

    env.close()
    print(f"\n  Mean reward over {num_episodes} episodes: {np.mean(rewards):.2f}")
    print(f"  Success rate (≥195): {np.mean([r >= 195 for r in rewards])*100:.1f}%")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model",    type=str,  default="policy_net.pth")
    parser.add_argument("--episodes", type=int,  default=10)
    parser.add_argument("--render",   action="store_true")
    args = parser.parse_args()

    evaluate(args.model, args.episodes, args.render)
