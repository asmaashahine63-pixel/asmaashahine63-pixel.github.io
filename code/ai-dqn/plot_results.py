"""
plot_results.py – Generate training curves from results.json.
Usage:
    python plot_results.py                    (uses results.json)
    python plot_results.py --file my_run.json
"""

import argparse
import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec


def rolling(data, window=50):
    result = []
    for i in range(len(data)):
        start = max(0, i - window + 1)
        result.append(np.mean(data[start:i+1]))
    return result


def plot(results_path: str = "results.json", out_path: str = "training_curves.png"):
    with open(results_path) as f:
        res = json.load(f)

    rewards  = res["episode_rewards"]
    steps    = res["episode_steps"]
    losses   = res["losses"]
    epsilons = res["epsilons"]
    hp       = res["hyperparams"]
    n        = len(rewards)
    episodes = np.arange(1, n + 1)

    fig = plt.figure(figsize=(16, 10), facecolor="#0f1117")
    fig.suptitle(
        "DQN Training Results – CartPole-v1",
        fontsize=18, fontweight="bold", color="white", y=0.98
    )
    gs = gridspec.GridSpec(2, 2, hspace=0.45, wspace=0.35,
                           left=0.07, right=0.97, top=0.93, bottom=0.08)

    ACCENT = "#00d4ff"
    DIM    = "#3a4a5a"
    WARN   = "#ff6b6b"
    OK     = "#6bff9e"

    def style_ax(ax, title):
        ax.set_facecolor("#1a2030")
        ax.set_title(title, color=ACCENT, fontsize=12, fontweight="bold", pad=8)
        ax.tick_params(colors="#8899aa")
        for spine in ax.spines.values():
            spine.set_color(DIM)
        ax.xaxis.label.set_color("#8899aa")
        ax.yaxis.label.set_color("#8899aa")
        ax.grid(alpha=0.15, color="#4a5a6a")

    # ── 1. Reward per episode ─────────────────
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.plot(episodes, rewards, color=DIM, lw=0.6, alpha=0.5, label="Episode reward")
    ax1.plot(episodes, rolling(rewards, 50), color=ACCENT, lw=2, label="50-ep avg")
    ax1.axhline(195, color=OK, lw=1.5, ls="--", label="Success threshold (195)")
    ax1.set_xlabel("Episode"); ax1.set_ylabel("Reward")
    ax1.legend(fontsize=8, labelcolor="white",
               facecolor="#1a2030", edgecolor=DIM)
    style_ax(ax1, "Episode Reward")

    # ── 2. Steps per episode ──────────────────
    ax2 = fig.add_subplot(gs[0, 1])
    ax2.plot(episodes, steps, color=DIM, lw=0.6, alpha=0.5)
    ax2.plot(episodes, rolling(steps, 50), color="#ffa94d", lw=2)
    ax2.axhline(500, color=OK, lw=1.5, ls="--", label="Max steps (500)")
    ax2.set_xlabel("Episode"); ax2.set_ylabel("Steps")
    ax2.legend(fontsize=8, labelcolor="white",
               facecolor="#1a2030", edgecolor=DIM)
    style_ax(ax2, "Steps per Episode")

    # ── 3. Training loss ──────────────────────
    ax3 = fig.add_subplot(gs[1, 0])
    nonzero_loss  = [(i+1, l) for i, l in enumerate(losses) if l > 0]
    if nonzero_loss:
        eps_nz, l_nz = zip(*nonzero_loss)
        ax3.plot(eps_nz, l_nz, color=WARN, lw=0.7, alpha=0.5)
        ax3.plot(eps_nz, rolling(list(l_nz), 50), color="#ff8888", lw=2)
    ax3.set_xlabel("Episode"); ax3.set_ylabel("MSE Loss")
    style_ax(ax3, "Training Loss (MSE)")

    # ── 4. Epsilon decay ─────────────────────
    ax4 = fig.add_subplot(gs[1, 1])
    ax4.plot(episodes, epsilons, color="#c678dd", lw=2)
    ax4.set_xlabel("Episode"); ax4.set_ylabel("Epsilon")
    ax4.set_ylim(0, 1.05)
    style_ax(ax4, "Epsilon Decay (Exploration)")

    # ── Hyperparameter box ────────────────────
    hp_text = (
        f"lr={hp['learning_rate']}  γ={hp['gamma']}  "
        f"ε₀={hp['epsilon']}  ε_decay={hp['epsilon_decay']}\n"
        f"batch={hp['batch_size']}  buffer={hp['replay_buffer_size']}  "
        f"target_upd={hp['target_update_freq']} eps"
    )
    fig.text(
        0.5, 0.005, hp_text,
        ha="center", va="bottom", fontsize=9,
        color="#8899aa", style="italic",
        bbox=dict(facecolor="#1a2030", edgecolor=DIM, boxstyle="round,pad=0.4")
    )

    plt.savefig(out_path, dpi=150, facecolor=fig.get_facecolor())
    print(f"  ✓ Plot saved → {out_path}")
    plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=str, default="results.json")
    parser.add_argument("--out",  type=str, default="training_curves.png")
    args = parser.parse_args()
    plot(args.file, args.out)
