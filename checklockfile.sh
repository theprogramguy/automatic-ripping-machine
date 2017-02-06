#!/bin/bash
(
         flock -n 9 && echo "UNLOCKED" || echo "LOCKED"
) 9>$1


